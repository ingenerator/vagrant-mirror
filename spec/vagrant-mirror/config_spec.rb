describe Vagrant::Mirror::Config do

  context "with no configuration" do

    it "defaults to using server port 8082" do
      subject.server_port.should eq(8082)
    end

    it "returns an empty array of mirrored folders" do
      subject.folders.should eq([])
    end

  end

  it "allows an alternate server port to be set" do
    subject.server_port = 8090
    subject.server_port.should eq 8090
  end

  it "provides a shortcut for mirroring the vagrant root to the guest" do
    subject.vagrant_root "/var/vagrant"
    
    subject.folders.count.should eq 1
    subject.folders[0][:host_path].should eq :vagrant_root
    subject.folders[0][:guest_path].should eq "/var/vagrant"
  end

  context "when adding folders to mirror" do

    it "adds each pair of folders to the stack" do
      subject.folder "c:\my\path", "/var/path"
      subject.folder "c:\my\other", "/var/path2"
      
      subject.folders.count.should eq 2
      subject.folders[0][:host_path].should eq "c:\my\path"
      subject.folders[1][:guest_path].should eq "/var/path2"
    end

  end

  context "when validating configuration" do

    before :each do
      @env = Vagrant::Environment.new
      @errors = Vagrant::Config::ErrorRecorder.new
    end
    
    it "rejects an invalid port number" do
      subject.server_port = 'ax90'
      subject.validate(@env, @errors)
      
      @errors.errors.empty?.should be_false
    end

    it "rejects folders with an empty host path" do
      subject.folder "", "/var/path"
      subject.validate(@env, @errors)
      
      @errors.errors.empty?.should be_false
    end

    it "rejects folders with an empty guest path" do
      subject.folder "c:\my\path", ""
      subject.validate(@env, @errors)
      
      @errors.errors.empty?.should be_false
    end
    
    it "rejects folders with nil paths" do
      subject.folder nil, nil
      subject.validate(@env, @errors)
      
      @errors.errors.count.should eq 2
    end

  end

  context "when merging configuration" do

    it "combines the folders from each configuration source" do
      subject.folder "c:\low-level", "/low-level"
      next_config = Vagrant::Mirror::Config.new
      next_config.folder "c:\top-level", "/top-level"
      merged = subject.merge(next_config)

      merged.should be_a Vagrant::Mirror::Config
      merged.folders.should have(2).items

      expected_result = [
        {:host_path => "c:\low-level", :guest_path => "/low-level"},
        {:host_path => "c:\top-level", :guest_path => "/top-level"}]

      merged.folders.should eq expected_result
    end
  end
end