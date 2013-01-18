describe Vagrant::Mirror::Command do
  describe "#execute" do
    context "with vagrant mirror sync" do
      it "runs the sync middleware"
      it "runs on the default vm only"
    end

    context "with vagrant mirror monitor" do
      it "runs the guestinstall middleware"
      it "runs the monitor middleware"
      it "runs on the default vm only"
    end

    context "with unknown command" do
      it "reports an error"
      it "lists valid commands"
      it "terminates the vagrant"
    end
  end
end