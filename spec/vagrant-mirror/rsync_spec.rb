describe Vagrant::Mirror::Rsync do

  # Shared mocks
  let (:vm)            { double("Vagrant::VM").as_null_object }
  let (:channel)       { double("Vagrant::Communication::SSH").as_null_object }
  let (:guest_sf_path) { '/vagrant' }
  let (:host_path)     { 'c:/vagrant' }
  let (:cfg_delete)    { false }
  let (:cfg_exclude)   { [] }
  let (:cfg_guest)     { '/var/vagrant' }
  let (:mirror_config) { { :name => 'v-root', :guest_path => '/var/vagrant', :delete => false,
                           :exclude => [], :beep => false, :symlinks => [] } }

  # Set basic stubs for shared mocks
  before (:each) do
    vm.stub(:channel).and_return channel

    File.stub(:directory?).and_return(false)
    File.stub(:directory?).with('c:/vagrant/dir').and_return(true)
  end

  subject { Vagrant::Mirror::Rsync.new(vm, guest_sf_path, host_path, mirror_config) }

  describe "#run" do

    shared_examples "running rsync to update the path" do | path, expect_source, expect_dest |
      context "with no exclude paths" do
        it "runs the expected rsync command" do
          channel.should_receive(:sudo).with("rsync -av #{expect_source} #{expect_dest}")

          subject.run(path)
        end
      end

      context "with exclude paths" do
        let (:mirror_config) { { :name => 'v-root', :guest_path => '/var/vagrant', :delete => false,
                           :exclude => ['/.git', 'cache'], :beep => false, :symlinks => [] } }

        it "runs the expected rsync command"  do
          channel.should_receive(:sudo).with("rsync -av --exclude '/.git' --exclude 'cache' #{expect_source} #{expect_dest}")

          subject.run(path)
        end
      end

      context "with delete enabled" do
        let (:mirror_config) { { :name => 'v-root', :guest_path => '/var/vagrant', :delete => true,
                           :exclude => [], :beep => false, :symlinks => [] } }

        it "runs the expected rsync command"  do
          channel.should_receive(:sudo).with("rsync -av --del #{expect_source} #{expect_dest}")

          subject.run(path)
        end
      end
    end

    context "when passed an empty path" do
      it_behaves_like "running rsync to update the path", '', '/vagrant/', '/var/vagrant/'
    end

    context "when passed the root path" do
      it_behaves_like "running rsync to update the path", '/', '/vagrant/', '/var/vagrant/'
    end

    context "when passed a file path" do
      it_behaves_like "running rsync to update the path", 'file', '/vagrant/file', '/var/vagrant/file'
    end

    context "when passed a directory path" do
      it_behaves_like "running rsync to update the path", 'dir', '/vagrant/dir/', '/var/vagrant/dir/'
    end

  end
end