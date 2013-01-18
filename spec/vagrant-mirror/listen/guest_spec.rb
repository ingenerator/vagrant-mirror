describe Vagrant::Mirror::Listen::TCP do
  describe "#listen!" do
    it "connects to the host socket"
    it "listens to the directory"

    context "when changes received" do
      it "receives the change notification"
      it "serialises the notification"
      it "sends the notification to the host"
    end

    context "with a close signal" do
      it "stops listening"
      it "closes the socket"
    end

    context "when the host is dropped" do
      it "reconnects to the host"
    end

    context "when the host is not available" do
      it "sends queued notifications"
    end

  end

  describe "#listen" do
    it "runs listen! in a new thread"
    it "passes the queue to the thread"
    it "returns the thread"
  end
end