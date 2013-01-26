describe Vagrant::Mirror::Middleware::Mirror do
  # Shared mocks
  let (:env)           { Vagrant::Action::Environment.new }
  let (:vm)            { double("Vagrant::VM").as_null_object }
  let (:ui)            { double("Vagrant::UI::Interface").as_null_object }
  let (:app)           { double("Object").as_null_object }
  let (:config)        { double("Object").as_null_object }
  let (:configmirror)  { double("Vagrant::Mirror::Config").as_null_object }
  let (:connection)    { double("Vagrant::Mirror::Connection::SFTP").as_null_object }
  let (:syncchanges)   { double("Vagrant::Mirror::Sync::Changes").as_null_object }
  let (:queue)         { double("Queue").as_null_object }
  let (:guard)         { double("Vagrant::Mirror::Listen::Host").as_null_object }

  # Set basic stubs for shared mocks
  before (:each) do
    env[:vm] = vm
    env[:ui] = ui

    vm.stub(:config).and_return config
    config.stub(:mirror).and_return configmirror

    app.stub(:call)

    Vagrant::Mirror::Connection::SFTP.stub(:new).and_return(connection)
    Vagrant::Mirror::Sync::Changes.stub(:new).and_return(syncchanges)
    Vagrant::Mirror::Listen::Host.stub(:new).and_return(guard)
    Queue.stub(:new).and_return(queue)

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

    context "with mirrored folders" do

      shared_examples "beginning mirroring" do
        it "creates a connection to the guest" do
          Vagrant::Mirror::Connection::SFTP.should_receive(:new)
            .with(vm, ui)
            .and_return(connection)

          subject.call(env)
        end

        it "logs the start of mirroring" do
          ui.should_receive(:info).with("Beginning directory mirroring")

          subject.call(env)
        end

        it "opens a new TCP notification listener"

        context "when the guest connection fails" do
          it "logs the failure"
          it "terminates the vagrant execution with an error"
        end

        context "when the TCP listener cannot start" do
          it "logs the failure"
          it "terminates the vagrant execution with an error"
        end

      end

      shared_examples "processing changes" do | host_path, guest_path |
        it "creates a sync changes class" do
          Vagrant::Mirror::Sync::Changes.should_receive(:new)
            .with(connection, host_path, guest_path, ui)
            .and_return(syncchanges)

          subject.call(env)
        end

        it "creates a Guard listener" do
          Vagrant::Mirror::Listen::Host.should_receive(:new)
            .with(host_path, queue)

          subject.call(env)
        end

        it "listens for changes in the host path" do
          guard.should_receive(:listen)

          subject.call(env)
        end

        context "with notifications in the queue" do
          let (:added)    { ['added'] }
          let (:modified) { ['modified','modified2'] }
          let (:removed)  { ['removed'] }

          before (:each) do
            queue.stub(:pop).and_return(
              { :source => :host, :added => added, :modified => modified, :removed => removed },
              { :source => :guest, :added => added, :modified => modified, :removed => removed },
              { :quit => true })

          end

          it "synchronises the first changes" do
            syncchanges.should_receive(:execute)
              .with(:host, added, modified, removed)

            subject.call(env)
            sleep 0.2
          end

          it "synchronises the second changes" do
            syncchanges.should_receive(:execute)
              .with(:guest, added, modified, removed)

            subject.call(env)
            sleep 0.2
          end

        end

        shared_examples "finishing mirroring" do
          it "signals the TCP listener to quit"
          it "signals the Guard listener to quit"
          it "waits for the TCP listener to quit"
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

      context "with defined paths" do
        before(:each) do
          configmirror.stub(:folders).and_return([
            {:host_path => 'c:/host', :guest_path => '/var/guest' }
          ])
        end

        it_behaves_like "beginning mirroring"
        it_behaves_like "processing changes", 'c:/host', '/var/guest'
        it_behaves_like "chained mirror middleware"
      end

      context "when mirroring the vagrant root" do
        before (:each) do
          configmirror.stub(:folders).and_return([
            {:host_path => :vagrant_root, :guest_path => '/var/vagrant' }
          ])

          env[:root_path] = 'c:/vagrant'
        end

        it_behaves_like "beginning mirroring"
        it_behaves_like "processing changes", 'c:/vagrant', '/var/vagrant'
        it_behaves_like "chained mirror middleware"
      end

      context "when mirroring multiple folders" do
        pending
      end

    end
  end
end