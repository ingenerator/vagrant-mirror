describe Vagrant::Mirror::Connection::SFTP do
  HOST_PATH  = 'C:/host'
  GUEST_PATH    = '/var/guest'
  GUEST_MISSING = '/var/guest/missing'
  GUEST_DIR     = '/var/guest/dir'

  MTIME      = 1358703212

  # Common stubs for all examples
  # Allow any method calls and set expectations in the scenarios
  let(:vm)          { double("Vagrant::VM") }
  let(:ui)          { double("Vagrant::UI::Interface").as_null_object }
  let(:sftp)        { double("Net::SFTP::Session").as_null_object }

  # Helper to define an SFTP status exception
  def status_exception(code)
    response = double("Net::SFTP::Response").as_null_object
    response.stub(:code).and_return(code)
    Net::SFTP::StatusException.new(response)
  end

  # Helper to define SFTP attributes
  def status_attributes(attrs = {})
    defaults = {
      :mtime => MTIME,
      :permissions => 0755
    }

    Net::SFTP::Protocol::V01::Attributes.new(defaults.merge(attrs))
  end

  subject { Vagrant::Mirror::Connection::SFTP.new(vm, ui) }

  before (:each) do
    # Stub the VM configuration
    ssh = double ("Vagrant::SSH")
    ssh.stub(:info).as_null_object.and_return({
      :host => 'vagranthost',
      :port => 22,
      :username => 'vagrantuser',
      :private_key_path => 'C:/vagrant/vagrant.key',
      :forward_agent => false
    })

    vm.stub(:ssh).as_null_object.and_return ssh

    # Stub the SFTP session
    Net::SFTP.stub(:start).as_null_object.and_return sftp
    sftp.stub(:closed?).and_return false

    # Stub stat responses for the known paths
    sftp.stub(:stat!).with(GUEST_PATH)
          .and_return(status_attributes)

    sftp.stub(:stat!).with(GUEST_MISSING)
          .and_raise(status_exception(Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE))

    sftp.stub(:stat!).with(GUEST_DIR)
          .and_return(status_attributes({:permissions => 040755}))
  end

  shared_examples "persistent connection" do | subject_method |
    context "with no connection" do
      it "connects to the guest" do
        Net::SFTP.should_receive(:start)

        subject_method.call(subject)
      end
    end

    context "with existing connection" do
      before(:each) do
        subject.connect
      end

      it "checks the connection is still open" do
        sftp.should_receive(:closed?).and_return false

        subject_method.call(subject)
      end

      it "re-uses the same connection" do
        Net::SFTP.should_not_receive(:start)

        subject_method.call(subject)
      end
    end

    context "when connection has dropped" do
      before(:each) do
        sftp.stub(:closed?).and_return true
      end

      it "reopens the connection" do
        Net::SFTP.should_receive(:start)

        subject_method.call(subject)
      end
    end
  end

  describe "#connect" do
    context "when attempting to connect" do
      it "reads the VM ssh configuration" do
        vm.ssh.should_receive(:info)

        subject.connect
      end

      it "passes the host name" do
        Net::SFTP.should_receive(:start)
          .with('vagranthost', anything(), anything())

        subject.connect
      end

      it "passes the user name" do
        Net::SFTP.should_receive(:start)
          .with(anything(), 'vagrantuser', anything())

        subject.connect
      end

      it "passes the port option" do
        Net::SFTP.should_receive(:start)
          .with(anything(), anything(), hash_including(:port => 22))

        subject.connect
      end

      it "passes the keys option" do
        Net::SFTP.should_receive(:start)
          .with(anything(), anything(), hash_including(:keys => ['C:/vagrant/vagrant.key']))

        subject.connect
      end

      it "sets keys_only authentication" do
        Net::SFTP.should_receive(:start)
          .with(anything(), anything(), hash_including(:keys_only => true))

        subject.connect
      end

      it "passes an empty known hosts file" do
        Net::SFTP.should_receive(:start)
          .with(anything(), anything(), hash_including(:user_known_hosts_file => []))

        subject.connect
      end

      it "does not use paranoid mode" do
        Net::SFTP.should_receive(:start)
          .with(anything(), anything(), hash_including(:paranoid => false))

        subject.connect
      end

      it "does not pass a config" do
        Net::SFTP.should_receive(:start)
          .with(anything(), anything(), hash_including(:config => false))

        subject.connect
      end

      it "does not forward the SSH agent" do
        Net::SFTP.should_receive(:start)
          .with(anything(), anything(), hash_including(:forward_agent => false))

        subject.connect
      end
    end

    context "when connection is not available at first" do
      it "waits a few seconds"
      it "retries the connection"
      it "raises an error after a few attempts"
    end
  end

  describe "#upload" do
    it_behaves_like "persistent connection", lambda {|subject| subject.upload(HOST_PATH, GUEST_PATH) }

    it "uploads asynchronously by SFTP" do
      sftp.should_receive(:upload).with(HOST_PATH, GUEST_PATH)

      subject.upload(HOST_PATH, GUEST_PATH)
    end

    it "logs the upload" do
      ui.should_receive(:info).with(">> #{HOST_PATH}")

      subject.upload(HOST_PATH, GUEST_PATH)
    end

    it "returns nil" do
      subject.upload(HOST_PATH, GUEST_PATH).should be_nil
    end
  end

  describe "#download" do
    it_behaves_like "persistent connection", lambda {|subject| subject.download(GUEST_PATH, HOST_PATH) }

    it "downloads asynchronously by SFTP" do
      sftp.should_receive(:download).with(GUEST_PATH, HOST_PATH)

      subject.download(GUEST_PATH, HOST_PATH)
    end

    it "logs the download" do
      ui.should_receive(:info).with("<< #{GUEST_PATH}")

      subject.download(GUEST_PATH, HOST_PATH)
    end

    it "returns nil" do
      subject.download(GUEST_PATH, HOST_PATH).should be_nil
    end
  end

  describe "#exists?" do

    it_behaves_like "persistent connection", lambda {|subject| subject.exists?(GUEST_PATH) }

    context "with existing file" do
      it "returns true" do
        subject.exists?(GUEST_PATH).should be_true
      end
    end

    context "with no existing file" do
      it "returns false" do
        subject.exists?(GUEST_MISSING).should be_false
      end
    end
  end

  describe "#mtime" do
    it_behaves_like "persistent connection", lambda {|subject| subject.mtime(GUEST_PATH) }

    context "with existing file" do
      it "returns a Time object" do
        subject.mtime(GUEST_PATH).should be_a Time
      end

      it "returns the right mtime" do
        subject.mtime(GUEST_PATH).to_i.should eq MTIME
      end
    end

    context "with no existing file" do
      it "returns nil" do
        subject.mtime(GUEST_MISSING).should be_nil
      end
    end
  end

  describe "#directory?" do
    it_behaves_like "persistent connection", lambda {|subject| subject.directory?(GUEST_DIR) }

    context "with existing file" do
      it "returns false" do
        subject.directory?(GUEST_PATH).should be_false
      end
    end

    context "with existing directory" do
      it "returns true" do
        subject.directory?(GUEST_DIR).should be_true
      end
    end

    context "with non-existent path" do
      it "returns false" do
        subject.directory?(GUEST_MISSING).should be_false
      end
    end
  end

  describe "#mkdir" do
    it_behaves_like "persistent connection", lambda {|subject| subject.mkdir(GUEST_DIR) }
    it "creates the directory"
    it "logs the directory creation"
  end

  describe "#dir_entries" do
    it_behaves_like "persistent connection", lambda {|subject| subject.dir_entries(GUEST_DIR) }

    context "with an empty directory" do
      it "returns an empty array"
    end

    context "with a directory of files" do
      it "returns an array of files"
    end

    context "with a directory of files and directories" do
      it "returns an array of files and directories"
    end
  end

  describe "#unlink" do
    it_behaves_like "persistent connection", lambda {|subject| subject.unlink(GUEST_DIR) }

    it "unlinks the file"
  end
end