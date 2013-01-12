describe Vagrant::Mirror::Sync::All do
  describe "#execute" do
    # Set up mocks
    let(:connection)  { double("Vagrant::Mirror::Connection::SFTP") }
    let(:ui)          { double("Vagrant::UI::Interface") }
    let(:host_root)   { 'C:/host' }
    let(:guest_root)  { '/var/guest' }

    # Set up default params for tests
    let(:mtime_new)   { 1357511119 }
    let(:mtime_old)   { 1357511118 }

    # Explicity create subject to pass in mocks
    subject { Vagrant::Mirror::Sync::All.new(connection, host_root, guest_root, ui) }

    shared_examples "transfer to guest with native recursion" do
      it "creates the guest path" do
        connection.stub(:upload!)
        connection.should_receive(:mkdir)
          .with(recursive_guest_path)
          .and_return(true)

        subject.execute('/')
      end

      it "uses native recursion to upload all" do
        connection.stub(:mkdir)
        connection.should_receive(:upload!)
          .with(recursive_host_path, recursive_guest_path, ui)

        subject.execute('/')
      end
    end

    context "when guest path is not present" do
      let (:recursive_guest_path) { '/var/guest' }
      let (:recursive_host_path)  { 'C:/host' }

      before (:each) do
        connection.should_receive(:exists?)
          .with('/var/guest')
          .and_return(false)
      end

      it_behaves_like "transfer to guest with native recursion"
    end

    context "when guest path is present" do

      # Set up a host filesystem
      let ( :host_files ) do
        { '.'  => {},
          '..' => {},
          'file-both-same' => Time.at(mtime_old),
          'file-host-mod'  => Time.at(mtime_new),
          'file-host-new'  => Time.at(mtime_new),
          'file-guest-mod' => Time.at(mtime_old),
          'dir-host-only'  => {
            'file-host-new' => Time.at(mtime_new)
          },
          'dir-both'       => {
            'file-both-same' => Time.at(mtime_old),
            'file-host-new'  => Time.at(mtime_new),
          }
        }
      end

      # Set up a guest filesystem
      let ( :guest_files ) do
        { '.'  => {},
          '..' => {},
          'file-both-same' => Time.at(mtime_old),
          'file-host-mod'  => Time.at(mtime_old),
          'file-guest-new'  => Time.at(mtime_new),
          'file-guest-mod' => Time.at(mtime_new),
          'dir-guest-only'  => {
            'file-guest-new' => Time.at(mtime_new)
          },
          'dir-both'       => {
            'file-both-same' => Time.at(mtime_old),
            'file-host-new'  => Time.at(mtime_old),
          }
        }
      end

      def build_host_fs_stubs(root, files)
        # Root path exists and is a directory
        File.stub(:exists?).with("#{root}").and_return(true)
        File.stub(:directory?).with("#{root}").and_return(true)

        # Process entries
        entries = []
        files.each do | file, value |
          entries << file
          if value.is_a? Hash
            # If value is a hash then this is a directory - recurse
            build_host_fs_stubs("#{root}/#{file}", value)
          else
            # Value is an mtime
            File.stub(:exists?).with("#{root}/#{file}").and_return(true)
            File.stub(:mtime).with("#{root}/#{file}").and_return(value)
          end
        end

        # And finally mock the entries call
        Dir.stub(:entries).with("#{root}").and_return(entries)
      end

      def build_guest_fs_stubs(root, files)
        # Root path exists and is a directory
        connection.stub(:exists?).with("#{root}").and_return(true)
        connection.stub(:directory?).with("#{root}").and_return(true)

        # Process entries
        entries = []
        files.each do | file, value |
          entries << file
          if value.is_a? Hash
            # If value is a hash then this is a directory - recurse
            build_guest_fs_stubs("#{root}/#{file}", value)
          else
            # Value is an mtime
            connection.stub(:mtime).with("#{root}/#{file}").and_return(value)
          end
        end

        # And finally mock the entries call
        connection.stub(:dir_entries).with("#{root}").and_return(entries)
      end

      # Set up mocks and stubs for fake filesystems
      before (:each) do

        # By default everything is a file and only things we specify exist
        File.stub(:directory?).and_return(false)
        File.stub(:exists?).and_return(false)
        File.stub(:mtime).and_return(nil)
        connection.stub(:mtime).and_return(nil)
        connection.stub(:directory?).and_return(false)
        connection.stub(:exists?).and_return(false)

        # Build the stubs for the host filesystem
        build_host_fs_stubs(host_root, host_files)
        build_guest_fs_stubs(guest_root, guest_files)

        # Allow any uploads and downloads - we assert them below
        connection.stub(:upload).as_null_object
        connection.stub(:download).as_null_object
        connection.stub(:mkdir).as_null_object
        connection.stub(:upload!).as_null_object
        ui.stub(:error).as_null_object
      end

      context "in the root dir" do
        it "does not upload the . directory" do
          connection.should_not_receive(:upload)
            .with('C:/host/.', '/var/guest/.')

          subject.execute('/')
        end

        it "does not upload the .. directory" do
          connection.should_not_receive(:upload)
            .with('C:/host/..', '/var/guest/..')

          subject.execute('/')
        end

        it "does not download the . directory" do
          connection.should_not_receive(:download)
            .with('C:/host/.', '/var/guest/.')

          subject.execute('/')
        end

        it "does not download the .. directory" do
          connection.should_not_receive(:download)
            .with('C:/host/..', '/var/guest/..')

          subject.execute('/')
        end

        it "uploads new files on the host to the guest" do
          connection.should_receive(:upload)
            .with('C:/host/file-host-new','/var/guest/file-host-new')

          subject.execute('/')
        end

        it "uploads changed files on the host to the guest" do
          connection.should_receive(:upload)
            .with('C:/host/file-host-mod','/var/guest/file-host-mod')

          subject.execute('/')
        end

        it "downloads new files on the guest to the host" do
          connection.should_receive(:download)
            .with('/var/guest/file-guest-new','C:/host/file-guest-new')

          subject.execute('/')
        end

        it "downloads changed files on the guest to the host" do
          connection.should_receive(:download)
            .with('/var/guest/file-guest-mod','C:/host/file-guest-mod')

          subject.execute('/')
        end

        it "does not download unchanged files" do
          connection.should_not_receive(:download)
            .with('/var/guest/file-both-same', 'C:/host/file-both-same')

          subject.execute('/')
        end

        it "does not upload unchanged files" do
          connection.should_not_receive(:upload)
            .with('C:/host/file-both-same', '/var/guest/file-both-same')

          subject.execute('/')
        end

        context "with directories" do
          let (:recursive_guest_path) { '/var/guest/dir-host-only' }
          let (:recursive_host_path)  { 'C:/host/dir-host-only' }

          it_behaves_like "transfer to guest with native recursion"
        end

        it "transfers new directories on the guest to the host"

      end

      context "one level down" do
        it "uploads new files on the host to the guest"
        it "uploads changed files on the host to the guest"
        it "downloads new files on the guest to the host"
        it "downloads changed files on the guest to the host"
        it "does not download unchanged files"
        it "does not upload unchanged files"
        it "transfers new directories on the host to the guest"
        it "transfers new directories on the guest to the host"
      end

    end
  end
end