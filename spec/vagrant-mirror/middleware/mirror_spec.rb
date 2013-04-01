describe Vagrant::Mirror::Middleware::Mirror do
  # Shared mocks
  let (:env)           { Vagrant::Action::Environment.new }
  let (:vm)            { double("Vagrant::VM").as_null_object }
  let (:ui)            { double("Vagrant::UI::Interface").as_null_object }
  let (:app)           { double("Object").as_null_object }
  let (:channel)       { double("Vagrant::Communication::SSH").as_null_object }
  let (:config)        { double("Object").as_null_object }
  let (:configmirror)  { Vagrant::Mirror::Config.new }
  let (:configvm)      { Vagrant::Config::VMConfig.new }
  let (:queue)         { double("Queue").as_null_object }
  let (:guard)         { double("Vagrant::Mirror::Listener::Host").as_null_object }
  let (:rsync)         { double("Vagrant::Mirror::Rsync").as_null_object }

  # Set basic stubs for shared mocks
  before (:each) do
    env[:vm] = vm
    env[:ui] = ui
    env[:root_path] = Dir.pwd

    vm.stub(:config).and_return config
    config.stub(:mirror).and_return configmirror
    config.stub(:vm).and_return configvm

    vm.stub(:channel).and_return channel

    Vagrant::Mirror::Rsync.stub(:new).and_return rsync

    app.stub(:call)

    Vagrant::Mirror::Listener::Host.stub(:new).and_return(guard)
    Queue.stub(:new).and_return(queue)
    queue.stub(:pop).and_return({ :quit => true})
  end

  subject { Vagrant::Mirror::Middleware::Mirror.new(app, env) }

  describe "#call" do
    shared_examples "chained mirror middleware" do
      it "calls the next middleware" do
        app.should_receive(:call).with(env)

        subject.call(env)
      end
    end

    context "with no mirrored folders" do
      before (:each) do
        configmirror.stub(:folders).and_return([])
      end

      it_behaves_like "chained mirror middleware"
    end

    context "with a mirrored folder" do

      before (:each) do
        config.mirror.vagrant_root '/var/guest'
        config.vm.share_folder("v-root", "/vagrant", ".")
      end

      it "logs the start of mirroring" do
        ui.should_receive(:info).with("Beginning directory mirroring")

        subject.call(env)
      end

      it "creates a Guard listener on the host path" do
        Vagrant::Mirror::Listener::Host.should_receive(:new)
          .with(env[:root_path], queue)

        subject.call(env)
      end

      context "creates an rsync class for the folder pair" do
        it "creates an rsync class for the folder pair" do
          Vagrant::Mirror::Rsync.should_receive(:new)
            .and_return(rsync)

          subject.call(env)
        end

        it "passes the vm to rsync" do
          Vagrant::Mirror::Rsync.should_receive(:new)
            .with(vm, anything, anything, anything)
            .and_return(rsync)

          subject.call(env)
        end

        it "passes the guest shared folder path for the folder pair to rsync" do
          Vagrant::Mirror::Rsync.should_receive(:new)
            .with(anything, "/vagrant", anything, anything)
            .and_return(rsync)

          subject.call(env)
        end

        it "passes the host shared folder path for the folder pair to rsync" do
          Vagrant::Mirror::Rsync.should_receive(:new)
            .with(anything, anything, env[:root_path], anything)
            .and_return(rsync)

          subject.call(env)
        end

        it "passes the folder configuration to rsync" do
          Vagrant::Mirror::Rsync.should_receive(:new)
            .with(anything, anything, anything, config.mirror.folders[0])
            .and_return(rsync)

          subject.call(env)
        end
      end

      it "listens for changes in the host path" do
        guard.should_receive(:listen)

        subject.call(env)
      end

      context "with notifications in the queue" do

        let (:added)     { ['added'] }
        let (:modified)  { ['modified','modified2'] }
        let (:removed)   { ['removed'] }
        let (:rm_exists) { true }

        before (:each) do
          queue.stub(:pop).and_return(
            { :added => added, :modified => modified, :removed => removed },
            { :added => added, :modified => modified, :removed => removed },
            { :quit => true })
          File.stub(:exists?).with("#{env[:root_path]}/removed").and_return(rm_exists)
        end

        it "runs rsync one by one for each added and modified file" do
          rsync.should_receive(:run).with("added")
          rsync.should_receive(:run).with("modified")
          rsync.should_receive(:run).with("modified2")

          subject.call(env)
          sleep 0.2
        end

        # Sometimes Guard flags a file as deleted that still exists - during certain types of
        # atomic file writes, we think. So we should delete the file remotely if so, or sync if not.
        context "if deleted files have been deleted" do
          let (:rm_exists) { false }

          it "deletes them by SSH" do
            channel.should_receive(:sudo).with('rm /var/guest/removed')

            subject.call(env)
            sleep 0.2
          end
        end

        context "if deleted files have not been deleted" do
          let (:rm_exists) { true }

          it "runs rsync on the file" do
            rsync.should_receive(:run).with('removed')

            subject.call(env)
            sleep 0.2
          end
        end

      end

      shared_examples "finishing mirroring" do
        it "signals the Guard listener to quit"
        it "waits for the Guard listener to quit"
        it "processes remaining jobs in the queue"
        it "calls the next middleware"
      end

      context "when signaled to quit" do
        it_behaves_like "finishing mirroring"
      end

      context "when user presses q on the console" do
        it_behaves_like "finishing mirroring"
      end
    end
  end
end