describe Vagrant::Mirror::Listen::Host do
  describe "#listen!" do
    it "listens to the host directory"

    context "when changes received" do
      it "receives the change notification"
      it "pushes the notification onto the queue"
    end

    context "with a close signal" do
      it "stops listening"
    end
  end

  describe "#listen" do
    it "runs listen! in a new thread"
    it "passes the queue to the thread"
    it "returns the thread"
  end
end