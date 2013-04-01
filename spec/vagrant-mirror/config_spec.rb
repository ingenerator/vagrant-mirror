describe Vagrant::Mirror::Config do

  context "with no configuration" do

    it "returns an empty array of mirrored folders" do
      subject.folders.should eq([])
    end

  end

  context "when a mirrored folder is added with no options" do

    before(:each) do
      subject.folder "foo", "/var/path"
    end

    it "adds it to the list of folders" do
      subject.folders.count.should eq 1
      subject.folders[0][:name].should eq 'foo'
      subject.folders[0][:guest_path].should eq "/var/path"
    end

    it "does not beep by default" do
      subject.folders[0][:beep].should be_false
    end

    it "does not delete by default" do
      subject.folders[0][:delete].should be_false
    end

    it "does not exclude anything by default" do
      subject.folders[0][:exclude].should eq([])
    end

    it "does not make any symlinks by default" do
      subject.folders[0][:symlinks].should eq([])
    end

  end

  it "provides a shortcut for mirroring the vagrant root to the guest" do
    subject.vagrant_root "/var/vagrant"

    subject.folders.count.should eq 1
    subject.folders[0][:name].should eq 'v-root'
    subject.folders[0][:guest_path].should eq "/var/vagrant"
  end

  it "can accept a folder with the delete option set" do
    subject.vagrant_root "/var/vagrant", { :delete => true }

    subject.folders[0][:delete].should be_true
  end

  it "can accept a folder with the beep option set" do
    subject.vagrant_root "/var/vagrant", { :beep => true }

    subject.folders[0][:beep].should be_true
  end

  it "can accept a folder with exclude patterns set" do
    subject.vagrant_root "/var/vagrant", { :exclude => ['/docs'] }

    subject.folders[0][:exclude].should eq(['/docs'])
  end

  context "when adding a folder with excludes and symlinks" do
    before (:each) do
      subject.vagrant_root "/var/vagrant", { :exclude => ['/docs'], :symlinks => ['/log'] }
    end

    it "stores the list of symlinks" do
      subject.folders[0][:symlinks].should eq(['/log'])
    end

    it "adds the symlink to the rsync exclude list" do
      subject.folders[0][:exclude].should eq(['/docs', '/log'])
    end

  end

  context "when adding multiple folders" do
    before (:each) do
      subject.vagrant_root "/var/vagrant", { :exclude => ['/docs'], :symlinks => ['/log'] }
      subject.folder "foo", "/var/foo", { :exclude => ['/docs2'], :symlinks => ['/log2'] }
    end

    it "builds a list of folders" do
      subject.folders.count.should eq(2)
      subject.folders[0][:name].should eq('v-root')
      subject.folders[1][:name].should eq('foo')
    end
  end

  context "when validating configuration" do

    before :each do
      @env = Vagrant::Environment.new
      @errors = Vagrant::Config::ErrorRecorder.new
    end

    it "rejects folders with an empty shared folder name" do
      subject.folder "", "/var/path"
      subject.validate(@env, @errors)

      @errors.errors.empty?.should be_false
    end

    it "rejects folders with an empty guest path" do
      subject.folder "foo", ""
      subject.validate(@env, @errors)

      @errors.errors.empty?.should be_false
    end

    it "rejects folders which are not already a vagrant shared folder" do
      pending
    end

    it "rejects folders with nil paths" do
      subject.folder nil, nil
      subject.validate(@env, @errors)
      @errors.errors.count.should eq 2
    end

    it "rejects unknown options" do
      subject.vagrant_root "/guest/path", { :foo => :bar }
      subject.validate(@env, @errors)

      @errors.errors.empty?.should be_false
    end

    it "validates with valid options" do
      subject.vagrant_root "/var/guest", { :symlinks => [ 'logs'], :exclude => ['exclude'], :delete => true, :beep => true }
      subject.validate(@env, @errors)

      @errors.errors.empty?.should be_true
    end

  end

  context "when merging configuration" do

    it "combines the folders from each configuration source" do
      subject.folder "low", "/low-level"
      next_config = Vagrant::Mirror::Config.new
      next_config.folder "top", "/top-level"
      merged = subject.merge(next_config)

      merged.should be_a Vagrant::Mirror::Config
      merged.folders.should have(2).items

      expected_result = [
        subject.folders[0],
        next_config.folders[0]
      ]

      merged.folders.should eq expected_result
    end
  end
end