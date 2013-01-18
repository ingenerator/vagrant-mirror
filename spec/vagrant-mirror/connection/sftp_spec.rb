describe Vagrant::Mirror::Connection::SFTP do
  shared_examples "persistent connection" do
    context "with no connection" do
      it "connects to the guest"
      it "does not close the connection"
    end

    context "with existing connection" do
      it "re-uses the same connection"
    end

    context "when connection has dropped" do
      it "reopens the connection"
    end
  end

  describe "#connect" do
    context "when connection is available" do
      it "gets credentials from config"
      it "connects via SFTP"
      it "stores the connection"
    end

    context "when connection is not available at first" do
      it "waits a few seconds"
      it "retries the connection"
      it "raises an error after a few attempts"
    end
  end

  describe "#upload" do
    it_behaves_like "persistent connection"
    it "uploads by SFTP"
    it "logs the upload"
  end

  describe "#download" do
    it_behaves_like "persistent connection"
    it "downloads by SFTP"
    it "logs the download"
  end

  describe "#exists?" do
    it_behaves_like "persistent connection"

    context "with existing file" do
      it "returns true"
    end

    context "with no existing file" do
      it "returns false"
    end
  end

  describe "#mtime" do
    it_behaves_like "persistent connection"

    context "with existing file" do
      it "fetches the mtime"
      it "returns a Time object"
    end

    context "with no existing file" do
      it "returns nil"
    end
  end

  describe "#directory?" do
    it_behaves_like "persistent connection"

    context "with existing file" do
      it "checks the path status"
      it "returns false"
    end

    context "with existing directory" do
      it "checks the path status"
      it "returns true"
    end

    context "with non-existent path" do
      it "checks the path status"
      it "raises an error"
    end
  end

  describe "#mkdir" do
    it_behaves_like "persistent connection"
    it "creates the directory"
    it "logs the directory creation"
  end

  describe "#dir_entries" do
    it_behaves_like "persistent connection"

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
    it_behaves_like "persistent connection"

    it "unlinks the file"
  end
end