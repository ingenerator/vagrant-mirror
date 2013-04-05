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

  describe "#call" do

    subject { Vagrant::Mirror::Middleware::Mirror.new(app, env) }

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
      let ( :mirror_options ) { {} }

      before (:each) do
        config.mirror.vagrant_root '/var/guest', mirror_options
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

        let (:added)            { { :event => :added, :path => 'added' } }
        let (:modified)         { { :event => :modified, :path => 'modified'} }
        let (:removed_exists)   { { :event => :removed, :path => 'removed_exists'}}
        let (:removed_remvd)    { { :event => :removed, :path => 'removed_remvd'}}

        before (:each) do
          queue.stub(:pop).and_return(
            added,
            modified,
            removed_exists,
            removed_remvd,
            { :quit => true }
          )

          File.stub(:exists?).with("#{env[:root_path]}/removed_exists").and_return(true)
          File.stub(:exists?).with("#{env[:root_path]}/removed_remvd").and_return(false)
        end

        it "runs rsync one by one for each added and modified file" do
          rsync.should_receive(:run).with("added")
          rsync.should_receive(:run).with("modified")

          subject.call(env)
          sleep 0.2
        end

        it "deletes files by SSH if they have been deleted on the host" do
          channel.should_receive(:sudo).with('rm /var/guest/removed_remvd')

          subject.call(env)
          sleep 0.2
        end

        it "runs rsync to update deleted files if they still exist on the host" do
          rsync.should_receive(:run).with('removed_exists')

          subject.call(env)
          sleep 0.2
        end
      end

      context "with notifications in the queue when exclude paths are configured" do
        let (:mirror_options) { { :exclude => [ "/docs", "cache", "*.png", "dir*", "/vendor/**/test"] } }

        # For these tests we want to know about unexpected calls
        let (:rsync)          { double("Vagrant::Mirror::Rsync") }

        it "correctly filters absolute paths within the sync folder" do
          queue.stub(:pop).and_return(
            { :event => :added, :path => "docs/should/ignore.fl" },
            { :event => :added, :path => "should/not/ignore/docs.txt" },
            { :quit => true })

          rsync.should_receive(:run).with('should/not/ignore/docs.txt')

          subject.call(env)
          sleep 0.2
        end

        it "correctly filters named directories within the sync folder" do
          queue.stub(:pop).and_return(
            { :event => :added, :path => "cache/should/ignore.fl" },
            { :event => :added, :path => "should/cache/ignore.fl" },
            { :event => :added, :path => "cacheit/should/not/ignore.fl" },
            { :quit => true })

          rsync.should_receive(:run).with('cacheit/should/not/ignore.fl')

          subject.call(env)
          sleep 0.2
        end

        it "correctly filters filename wildcards" do
          queue.stub(:pop).and_return(
            { :event => :added, :path => "ignore.png" },
            { :event => :added, :path => "should/ignore.png" },
            { :event => :added, :path => "should/not/png/ignore.txt" },
            { :quit => true })

          rsync.should_receive(:run).with('should/not/png/ignore.txt')

          subject.call(env)
          sleep 0.2
        end

        it "correctly filters glob patterns with *" do
          queue.stub(:pop).and_return(
            { :event => :added, :path => "dir1/should/ignore.fl" },
            { :event => :added, :path => "should/dirignore/this.tst" },
            { :event => :added, :path => "should/notdir/ignore.tst" },
            { :quit => true })

          rsync.should_receive(:run).with('should/notdir/ignore.tst')

          subject.call(env)
          sleep 0.2
        end

        it "correctly filters glob patterns with **" do
          queue.stub(:pop).and_return(
            { :event => :added, :path => "vendor/my/test/file.tst" },
            { :event => :added, :path => "vendor/my/deep/test/file.tst" },
            { :event => :added, :path => "vendor/test/file.tst" },
            { :quit => true })

          rsync.should_receive(:run).with('vendor/test/file.tst')

          subject.call(env)
          sleep 0.2
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