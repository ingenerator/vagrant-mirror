describe Vagrant::Mirror::Middleware::Sync do
  describe "#call" do
    context "with no mirrored folders" do
      it "calls the next middleware"
    end
    
    context "with mirrored folders" do
      it "loads ssh params from env"
      it "loads folders from config"
      it "creates a connection to the guest"
      it "logs the start of mirroring"
      it "logs the end of mirroring"
      it "waits until all transfers are complete"
      it "calls the next middleware"
      
      context "when the guest connection fails" do
        it "logs the failure"
        it "terminates the vagrant execution with an error"
      end
      
      shared_examples "folder synchronisation" do | host_path, guest_path |
        it "creates a sync all class"
        it "passes the connection"
        it "passes the ui"
        it "passes the host path"
        it "passes the guest path"
        it "runs the sync all action"

      end
      
      context "with defined paths" do
        it_behaves_like "folder synchronisation", "c:/host", "/var/guest"
      end
      
      context "when mirroring the vagrant root" do
        it "maps the vagrant root path"
        it_behaves_like "folder synchronisation", "c:/vagrant", "/var/vagrant"
      end
      
      context "with two mirror pairs" do
        it_behaves_like "folder synchronisation", "c:/host1", "/var/host1"
        it_behaves_like "folder synchronisation", "c:/host2", "/var/host2"
      end
    end
  end
end