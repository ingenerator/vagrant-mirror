describe Vagrant::Mirror::Middleware::GuestInstall do
  describe "#call" do
    context "when the guest is reachable" do
      it "installs the listen gem"
      it "installs the inotify gem"
      it "installs the monitor service"
      it "runs the monitor service"
      it "calls the next middleware"
    end

    context "when the guest is unreachable" do
      it "logs the connection failure"
      it "terminates the vagrant execution with an error"
    end
  end
end