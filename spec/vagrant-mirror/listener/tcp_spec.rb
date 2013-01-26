describe Vagrant::Mirror::Listener::TCP do
  describe "#listen!" do
    it "opens a TCP server"
    it "listens on configured port"

    context "with valid messages" do
      it "receives the message"
      it "deserialises the client message"
      it "puts the notification onto the queue"
      it "waits for the next message"
    end

    context "with invalid messages" do
      it "handles corrupt length fields"
      it "handles deserialise errors"
      it "reports an error on the UI"
      it "waits for the next message"
    end

    context "with no messages" do
      it "waits for the next message"
      it "closes on a signal"
    end

    context "when the connection is dropped" do
      it "opens a new listening connection"
    end

  end

  describe "#listen" do
    it "runs listen! in a new thread"
    it "passes the queue to the thread"
    it "returns the thread"
  end
end