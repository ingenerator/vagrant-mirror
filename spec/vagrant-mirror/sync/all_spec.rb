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
          'file-host-mod'  => Time.at(mtime_new),
          'file-host-new'  => Time.at(mtime_new),
          'file-guest-mod' => Time.at(mtime_old),
          'dir-host-only'  => {
            'file-host-new' => Time.at(mtime_new)
          },
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
          'file-host-mod'  => Time.at(mtime_old),
          'file-guest-new'  => Time.at(mtime_new),
          'file-guest-mod' => Time.at(mtime_new),
          'dir-guest-only'  => {
            'file-guest-new' => Time.at(mtime_new)
          },
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
      # and directories that don't exist return empty
      # Specific mocks and expectations are set in the relevant tests or contexts
      File.stub(:directory?).and_return(false)
      File.stub(:exists?).and_return(false)
      File.stub(:mtime).and_return(nil)
      Dir.stub(:entries).and_return([]).as_null_object
      connection.stub(:mtime).and_return(nil)
      connection.stub(:directory?).and_return(false)
      connection.stub(:exists?).and_return(false)
      connection.stub(:dir_entries).and_return([])

      # Build the stubs for the host filesystem
      build_host_fs_stubs(host_root, host_files)
      build_guest_fs_stubs(guest_root, guest_files)

      # Allow any uploads and downloads - we assert them below
      connection.stub(:upload).as_null_object
      connection.stub(:download).as_null_object
      connection.stub(:mkdir).as_null_object
      connection.stub(:upload!).as_null_object
      ui.stub(:error).as_null_object
      FileUtils.stub(:mkdir_p).as_null_object
    end

    shared_examples "folder synchronisation" do |host_base, guest_base|

      context "when guest path is not present" do
        before (:each) do
          connection.stub(:exists?)
            .with(guest_base)
            .and_return(false)
        end

        it "creates the guest path" do
          connection.should_receive(:mkdir)
            .with(guest_base)

          subject.execute('/')
        end
      end

      context "when host path is not present" do
        before (:each) do
          File.stub(:exists?)
            .with(host_base)
            .and_return(false)
        end

        it "creates the host path" do
          FileUtils.should_receive(:mkdir_p)
            .with(host_base)
            .and_return(true)

          subject.execute('/')
        end
      end

      it "does not upload the . directory" do
        connection.should_not_receive(:upload)
          .with("#{host_base}/.", "#{guest_base}/.", anything())

        subject.execute('/')
      end

      it "does not upload the .. directory" do
        connection.should_not_receive(:upload)
          .with("#{host_base}/..", "#{guest_base}/..", anything())

        subject.execute('/')
      end

      it "does not download the . directory" do
        connection.should_not_receive(:download)
          .with("#{guest_base}/.", "#{host_base}/.", anything())

        subject.execute('/')
      end

      it "does not download the .. directory" do
        connection.should_not_receive(:download)
          .with("#{guest_base}/..", "#{host_base}/..", anything())

        subject.execute('/')
      end

      it "uploads new files on the host to the guest" do
        connection.should_receive(:upload)
          .with("#{host_base}/file-host-new", "#{guest_base}/file-host-new", Time.at(mtime_new))

        subject.execute('/')
      end

      it "uploads changed files on the host to the guest" do
        connection.should_receive(:upload)
          .with("#{host_base}/file-host-mod", "#{guest_base}/file-host-mod", Time.at(mtime_new))

        subject.execute('/')
      end

      it "downloads new files on the guest to the host" do
        connection.should_receive(:download)
          .with("#{guest_base}/file-guest-new", "#{host_base}/file-guest-new", Time.at(mtime_new))

        subject.execute('/')
      end

      it "downloads changed files on the guest to the host" do
        connection.should_receive(:download)
          .with("#{guest_base}/file-guest-mod", "#{host_base}/file-guest-mod", Time.at(mtime_new))

        subject.execute('/')
      end

      it "does not download unchanged files" do
        connection.should_not_receive(:download)
          .with("#{guest_base}/file-both-same", "#{host_base}/file-both-same", anything())

        subject.execute('/')
      end

      it "does not upload unchanged files" do
        connection.should_not_receive(:upload)
          .with("#{host_base}/file-both-same", "#{guest_base}/file-both-same", anything())

        subject.execute('/')
      end


    end

    context "in the root dir" do
      it_behaves_like "folder synchronisation", 'C:/host', '/var/guest'
    end

    context "one level down" do
      it_behaves_like "folder synchronisation", 'C:/host/dir-both', '/var/guest/dir-both'
    end

    context "in directories missing from host" do
      it "downloads new files on the guest to the host" do
        connection.should_receive(:download)
          .with("/var/guest/dir-guest-only/file-guest-new", "C:/host/dir-guest-only/file-guest-new", Time.at(mtime_new))

        subject.execute('/')
      end

    end

    context "in directories missing from guest" do
      it "uploads new files on the host to the guest" do
        connection.should_receive(:upload)
          .with("C:/host/dir-host-only/file-host-new", "/var/guest/dir-host-only/file-host-new", Time.at(mtime_new))

        subject.execute('/')
      end
    end

  end
end