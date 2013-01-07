describe Vagrant::Mirror::FileSynchroniser do

  let(:ssh)        { double(Net::SSH::Connection::Session) }
  let(:host_root)  { 'C:\host' }
  let(:guest_root) { '/var/guest' }
  let(:mtime_new)  { 1357511119 }

  describe "#absolute_paths" do

    subject do
      Vagrant::Mirror::FileSynchroniser.new(ssh, host_root, guest_root)
        .absolute_paths('path/to/my/file')
    end

    its [:guest] { should eq '/var/guest/path/to/my/file' }
    its [:host]  { should eq 'C:\host/path/to/my/file' }

  end

  describe "#host_mtime" do

    context "when the file exists" do

      subject do
        Vagrant::Mirror::FileSynchroniser.new(ssh, host_root, guest_root)
          .host_mtime('C:\host/path/to/my/file')
      end

      before (:each) do
        File.should_receive(:exists?).with('C:\host/path/to/my/file').and_return(true)
        File.should_receive(:mtime).with('C:\host/path/to/my/file').and_return(Time.at(mtime_new))
      end

      it { should be_a Time }

      it "returns the correct modification time" do
        should eq Time.at(mtime_new)
      end

    end
    
    context "when the file does not exist" do

      subject do
        Vagrant::Mirror::FileSynchroniser.new(ssh, host_root, guest_root)
          .host_mtime('C:\host/path/to/no/file')
      end

      before (:each) do
        File.should_receive(:exists?).with('C:\host/path/to/no/file').and_return(false)
        File.should_not_receive(:mtime).with('C:\host/path/to/no/file')
      end

      it { should be_nil }

    end

  end
  
  describe "#guest_mtime" do

    context "when the file exists" do

      subject do
        Vagrant::Mirror::FileSynchroniser.new(ssh, host_root, guest_root)
          .guest_mtime('/var/guest/path/to/my/file')
      end

      before (:each) do
        ssh.should_receive(:exec!).with('stat -c %Y /var/guest/path/to/my/file').and_return(mtime_new)
      end

      it { should be_a Time }

      it "returns the correct modification time" do
        should eq Time.at(mtime_new)
      end

    end
    
    context "when the file does not exist" do

      subject do
        Vagrant::Mirror::FileSynchroniser.new(ssh, host_root, guest_root)
          .guest_mtime('/var/guest/path/to/no/file')
      end

      before (:each) do
        ssh.should_receive(:exec!).with('stat -c %Y /var/guest/path/to/no/file').and_return("stat: cannot stat `nofile': No such file or directory")
      end

      it { should be_nil }

    end

  end

  describe "#sync_everything!" do

    context "when the guest directory does not exist" do

      it "uses recursive scp to copy the whole directory from the host" do
        pending
      end

    end

    context "when the guest directory exists" do

      it "sends missing files to the guest" do
        pending
      end

      it "sends newer files to the guest" do
        pending
      end


      it "retrieves missing files from the host" do
        pending
      end


      it "retrieves newer files from the guest" do
        pending
      end

    end

  end

  describe "#sync_added" do

    context "when the host file is older" do
      pending
    end

    context "when the host file is newer" do
      pending
    end

    context "when the host file is the same" do
      pending
    end

    context "when the host file is missing" do
      pending
    end

  end

  describe "#sync_deleted" do

    context "when triggered from the guest" do

      context "when the file exists on the host" do

        pending

      end

      context "when the file does not exist on the host" do

        pending

      end

    end

    context "when triggered from the host" do

      context "when the file exists on the guest" do

        pending

      end

      context "when the file does not exist on the guest" do

        pending

      end

    end

  end

end