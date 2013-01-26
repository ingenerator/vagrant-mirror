describe Vagrant::Mirror::Sync::Changes do
  describe "#execute" do
    let(:connection)  { double("Vagrant::Mirror::Connection::SFTP") }
    let(:ui)          { double("Vagrant::UI::Interface") }
    let(:host_root)   { 'C:/host' }
    let(:guest_root)  { '/var/guest' }

    let(:mtime_new)   { 1357511119 }
    let(:mtime_old)   { 1357511118 }

    # Default params for execute, overridden in contexts lower down
    let(:added)       { [] }
    let(:modified)    { [] }
    let(:removed)     { [] }
    let(:source)      { :host }

    # Explicity create subject to pass in mocks
    subject { Vagrant::Mirror::Sync::Changes.new(connection, host_root, guest_root, ui) }

    # ========================================================================
    # Begin scenarios
    # ========================================================================

    # All files added or modified on either side of the mirror behave the same
    shared_examples "a modified file" do

      # Default params for mock expectations, overridden for each scenario
      let (:full_host_path)   { "C:/host/#{test_file}" }
      let (:full_guest_path)  { "/var/guest/#{test_file}" }
      let (:host_exists)      { true }
      let (:host_mtime)       { nil }
      let (:host_expct_mtime) { true }
      let (:guest_mtime)      { nil }

      # Set up mock expectations based on let values from each block
      before (:each) do
        File.should_receive(:exists?)
            .with(full_host_path)
            .and_return(host_exists)

        if host_expct_mtime
          File.should_receive(:mtime)
              .with(full_host_path)
              .and_return(host_mtime)
        else
          File.should_not_receive(:mtime)
              .with(full_host_path)
        end

        connection.should_receive(:mtime)
              .with(full_guest_path)
              .and_return(guest_mtime)
      end

      context "when file is newer on host" do
        let (:host_exists)      { true }
        let (:host_mtime)       { Time.at(mtime_new) }
        let (:host_expct_mtime) { true }
        let (:guest_mtime)      { Time.at(mtime_old) }

        it "transfers to the guest" do
          connection.should_receive(:upload)
               .with("C:/host/#{test_file}", "/var/guest/#{test_file}", Time.at(mtime_new))

          subject.execute(source, added, modified, removed)
        end

      end

      context "when file is newer on guest" do
        let (:host_exists)      { true }
        let (:host_mtime)       { Time.at(mtime_old) }
        let (:host_expct_mtime) { true }
        let (:guest_mtime)      { Time.at(mtime_new) }

        it "transfers to the host" do
          connection.should_receive(:download)
               .with("/var/guest/#{test_file}","C:/host/#{test_file}", Time.at(mtime_new))

          subject.execute(source, added, modified, removed)
        end
      end

      context "when file is missing on host" do
        let (:host_exists)      { false }
        let (:host_mtime)       { nil }
        let (:host_expct_mtime) { false }
        let (:guest_mtime)      { Time.at(mtime_new) }

        it "transfers to the host" do
          connection.should_receive(:download)
               .with("/var/guest/#{test_file}","C:/host/#{test_file}", Time.at(mtime_new))

          subject.execute(source, added, modified, removed)
        end
      end

      context "when file is missing on guest" do
        let (:host_exists)      { true }
        let (:host_mtime)       { Time.at(mtime_new) }
        let (:host_expct_mtime) { true }
        let (:guest_mtime)      { nil }

        it "transfers to the guest" do
          connection.should_receive(:upload)
               .with("C:/host/#{test_file}","/var/guest/#{test_file}", Time.at(mtime_new))

          subject.execute(source, added, modified, removed)
        end
      end

      context "when file is missing on both" do
        let (:host_exists)      { false }
        let (:host_mtime)       { nil }
        let (:host_expct_mtime) { false }
        let (:guest_mtime)      { nil }

        it "reports an error" do
          ui.should_receive(:error)
            .with("#{full_host_path} was not found on either the host or guest filesystem - cannot sync")

          subject.execute(source, added, modified, removed)
        end

      end

      context "when file is same on both" do
        let (:host_exists)      { true }
        let (:host_mtime)       { Time.at(mtime_old) }
        let (:host_expct_mtime) { true }
        let (:guest_mtime)      { Time.at(mtime_old) }

        it "does not upload" do
          connection.should_not_receive(:upload)

          subject.execute(source, added, modified, removed)
        end

        it "does not download" do
          connection.should_not_receive(:download)

          subject.execute(source, added, modified, removed)
        end
      end
    end

    context "when file is added to host" do
      let(:added)     { ['my/new/file'] }
      let(:test_file) { 'my/new/file' }

      it_behaves_like "a modified file"
    end

    context "when file is modified on host" do
      let(:modified)  { ['my/changed/file'] }
      let(:test_file) { 'my/changed/file' }

      it_behaves_like "a modified file"
    end

    context "when file is added to guest" do
      let(:added)     { ['my/new/file'] }
      let(:test_file) { 'my/new/file' }
      let(:source)    { :guest }

      it_behaves_like "a modified file"
    end

    context "when file is modified on guest" do
      let(:modified)  { ['my/changed/file'] }
      let(:test_file) { 'my/changed/file' }
      let(:source)    { :guest }

      it_behaves_like "a modified file"
    end

    context "when file is deleted from host" do
      let (:removed)         { ['my/deleted/file'] }
      let (:test_file)       { 'my/deleted/file' }
      let (:source)          { :host }
      let (:full_guest_path) { "/var/guest/#{test_file}" }
      let (:guest_mtime)     { nil }

      before (:each) do
        connection.should_receive(:mtime)
              .with(full_guest_path)
              .and_return(guest_mtime)
      end

      context "when guest path exists" do
        let (:guest_mtime)      { Time.at(mtime_old) }

        it "deletes from guest" do
          connection.should_receive(:delete)
               .with(full_guest_path)

          subject.execute(source, added, modified, removed)
        end
      end

      context "when guest path does not exist" do
        let (:guest_mtime)      { nil}

        it "does not delete and issues an info message" do
          connection.should_not_receive(:delete)
          ui.should_receive(:info)
            .with("#{test_file} was not found on guest - nothing to delete")

          subject.execute(source, added, modified, removed)
        end
      end
    end

    context "when file is deleted from guest" do
      let (:removed)         { ['my/deleted/file'] }
      let (:test_file)       { 'my/deleted/file' }
      let (:source)          { :guest }
      let (:full_host_path)  { "C:/host/#{test_file}" }
      let (:host_exists)     { nil }

      before (:each) do
        File.should_receive(:exists?)
              .with(full_host_path)
              .and_return(host_exists)
      end

      context "when host path exists" do
        let (:host_exists)  { true }

        it "deletes from host" do
          File.should_receive(:delete)
               .with(full_host_path)

          subject.execute(source, added, modified, removed)
        end
      end

      context "when host path does not exist" do
        let (:host_exists)  { false }

        it "does not delete and issues an info message" do
          File.should_not_receive(:delete)
          ui.should_receive(:info)
            .with("#{test_file} was not found on host - nothing to delete")

          subject.execute(source, added, modified, removed)
        end
      end
    end
  end
end