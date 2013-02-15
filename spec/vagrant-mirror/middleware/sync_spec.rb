describe Vagrant::Mirror::Middleware::Sync do
  # Shared mocks
  let (:env)           { Vagrant::Action::Environment.new }
  let (:vm)            { double("Vagrant::VM").as_null_object }
  let (:ui)            { double("Vagrant::UI::Interface").as_null_object }
  let (:app)           { double("Object").as_null_object }
  let (:config)        { double("Object").as_null_object }
  let (:configmirror)  { double("Vagrant::Mirror::Config").as_null_object }
  let (:connection)    { double("Vagrant::Mirror::Connection::SFTP").as_null_object }

  # Set basic stubs for shared mocks
  before (:each) do
    env[:vm] = vm
    env[:ui] = ui

    vm.stub(:config).and_return config
    config.stub(:mirror).and_return configmirror

    app.stubb(:call)

    Vagrant::Mirror::Connection::SFTP.stub(:new).and_return(connection)
    Vagrant::Mirror::Sync::All.stub(:new) { double("Vagrant::Mirror::Sync::All") }
  end

  subject { Vagrant::Mirror::Middleware::Sync.new(app, env) }

  describe "#call" do

    shared_examples "chained middleware" do
      it "calls the next middleware" do
        app.should_receive(:call).with(env)

        subject.call(env)
      end
    end

    context "with no mirrored folders" do
      before (:each) do
        configmirror.stub(:folders).and_return([])
      end

      it_behaves_like "chained middleware"
    end

    context "with mirrored folders" do
      let (:syncall1)       { double("Vagrant::Mirror::Sync::All").as_null_object }
      let (:syncall2)       { double("Vagrant::Mirror::Sync::All").as_null_object }

      shared_examples "beginning transfers" do
        it "creates a connection to the guest" do
          Vagrant::Mirror::Connection::SFTP.should_receive(:new)
            .with(vm, ui)
            .and_return(connection)

          subject.call(env)
        end

        it "logs the start of mirroring" do
          ui.should_receive(:info).with("Beginning directory synchronisation")

          subject.call(env)
        end
      end

      shared_examples "middleware folder sync" do | host_path, guest_path, syncseq |
        it "creates a sync all class" do
          Vagrant::Mirror::Sync::All.should_receive(:new)
            .with(connection, host_path, guest_path, ui)
            .and_return(syncall1)

          subject.call(env)
        end

        it "runs the sync all action" do
          if syncseq == 1
            syncall1.should_receive(:execute).with("/")
          elsif syncseq == 2
            syncall2.should_receive(:execute).with("/")
          else
            pending
          end

          subject.call(env)
        end
      end

      shared_examples "completing transfers" do
        it "waits until all transfers are complete" do
          connection.should_receive(:finish_transfers)

          subject.call(env)
        end

        it "logs the end of mirroring" do
          ui.should_receive(:success).with("Completed directory synchronisation")

          subject.call(env)
        end

        it "closes the connection" do
          connection.should_receive(:close)

          subject.call(env)
        end

        it_behaves_like "chained middleware"
      end

      context "with defined paths" do
        before (:each) do
          configmirror.stub(:folders).and_return([
            {:host_path => 'c:/host', :guest_path => '/var/guest' }
          ])

          Vagrant::Mirror::Sync::All.stub(:new)
            .with(connection, 'c:/host', '/var/guest', ui)
            .and_return(syncall1)
        end

        it_behaves_like "beginning transfers"
        it_behaves_like "middleware folder sync", "c:/host", "/var/guest", 1
        it_behaves_like "completing transfers"

        context "when encountering a non-vagrant error" do
          before (:each) do
            Vagrant::Mirror::Connection::SFTP.stub(:new)
              .with(vm, ui)
              .and_raise(RuntimeError.new("whoops"))
          end

          it "converts to a Vagrant error" do
            expect { subject.call(env) }.to raise_error(Vagrant::Mirror::Errors::Error, /whoops/)
          end
        end
      end

      context "when mirroring the vagrant root" do
        before (:each) do
          configmirror.stub(:folders).and_return([
            {:host_path => :vagrant_root, :guest_path => '/var/vagrant' }
          ])

          env[:root_path] = 'c:/vagrant'

          Vagrant::Mirror::Sync::All.stub(:new)
            .with(connection, 'c:/vagrant', '/var/vagrant', ui)
            .and_return(syncall1)
        end

        it_behaves_like "beginning transfers"
        it_behaves_like "middleware folder sync", "c:/vagrant", "/var/vagrant", 1
        it_behaves_like "completing transfers"
      end

      context "with two mirror pairs" do
        before (:each) do
          configmirror.stub(:folders).and_return([
            {:host_path => 'c:/host1', :guest_path => '/var/guest1' },
            {:host_path => 'c:/host2', :guest_path => '/var/guest2' }
          ])

          Vagrant::Mirror::Sync::All.stub(:new)
            .with(connection, 'c:/host1', '/var/guest1', ui)
            .and_return(syncall1)

          Vagrant::Mirror::Sync::All.stub(:new)
            .with(connection, 'c:/host2', '/var/guest2', ui)
            .and_return(syncall2)
        end

        it_behaves_like "beginning transfers"
        it_behaves_like "middleware folder sync", "c:/host1", "/var/guest1", 1
        it_behaves_like "middleware folder sync", "c:/host2", "/var/guest2", 2
        it_behaves_like "completing transfers"
      end

      context "when the guest connection fails" do
        it "logs the failure"
        it "terminates the vagrant execution with an error"
      end
    end
  end
end