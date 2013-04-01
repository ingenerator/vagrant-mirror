describe Vagrant::Mirror::Middleware::Sync do
  # Shared mocks
  let (:env)           { Vagrant::Action::Environment.new }
  let (:vm)            { double("Vagrant::VM").as_null_object }
  let (:channel)       { double("Vagrant::Communication::SSH").as_null_object }
  let (:ui)            { double("Vagrant::UI::Interface").as_null_object }
  let (:app)           { double("Object").as_null_object }
  let (:config)        { double("Object").as_null_object }
  let (:configmirror)  { Vagrant::Mirror::Config.new }
  let (:configvm)      { Vagrant::Config::VMConfig.new }
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
      it_behaves_like "chained middleware"
    end

    context "with a mirrored folder" do
      before (:each) do
        config.mirror.vagrant_root '/var/guest'
        config.vm.share_folder("v-root", "/vagrant", ".")
      end

      it_behaves_like "chained middleware"

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

      it "runs rsync for the root of the mirrored folder" do
        rsync.should_receive(:run)
          .with("/")

        subject.call(env)
      end
    end

    context "with two mirrored folders" do
      before (:each) do
        config.mirror.folder "foo", "/var/foo"
        config.mirror.folder "bar", "/var/bar"
      end

      it "throws an exception as this is not yet supported" do
        expect { subject.call(env) }.to raise_error(Vagrant::Mirror::Errors::MultipleFoldersNotSupported)
      end
    end

    context "when the mirror config includes symlinks" do
      let (:host_path) { File.join(Dir.pwd, 'logs') }

      before (:each) do
        config.mirror.vagrant_root "/var/vagrant", { :symlinks => ['logs'] }
        config.vm.share_folder("v-root", "/vagrant", ".")

        File.stub(:exists?).with(host_path).and_return true
      end

      context "if the host folder does not exist" do
        let (:host_path) { File.join(Dir.pwd, 'logs') }

        before (:each) do
          File.stub(:exists?).with(host_path).and_return false
        end

        it "creates the folder on the host" do
          FileUtils.stub(:mkdir_p).with(host_path)
        end
      end

      it "creates a symlink on the guest" do
        channel.should_receive(:sudo).with('rm -f /var/vagrant/logs && mkdir -p /var/vagrant && ln -s /vagrant/logs /var/vagrant/logs')

        subject.call(env)
      end
    end

    context "when the mirrored config includes invalid shared folders" do
      before (:each) do
        config.mirror.folder "unknown", "/var/whoops"
      end

      it "throws an exception" do
        expect { subject.call(env) }.to raise_error(Vagrant::Mirror::Errors::SharedFolderNotMapped)
      end
    end
  end
end