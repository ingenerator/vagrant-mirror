describe Vagrant::Mirror::Middleware::Mirror do
  describe "#call" do
    context "with no mirrored folders" do
      it "calls the next middleware"
    end

    context "with mirrored folders" do
      it "loads ssh params from env"
      it "loads folders from config"
      it "creates a connection to the guest"
      it "opens a new TCP notification listener"

      context "when the guest connection fails" do
        it "logs the failure"
        it "terminates the vagrant execution with an error"
      end

      context "when the TCP listener cannot start" do
        it "logs the failure"
        it "terminates the vagrant execution with an error"
      end

      shared_examples "creating a mirror class" do | host_path, guest_path |
        it "creates a sync::mirror"
        it "passes the connection"
        it "passes the ui"
        it "passes the host path"
        it "passes the guest path"
      end

      shared_examples "creating a guard listener" do | host_path, guest_path |
        it "listens for filesystem changes in the host path"
      end

      context "with defined paths" do
        it_behaves_like "creating a mirror class", 'C:/host','/var/guest'
        it_behaves_like "creating a guard listener", 'C:/host','/var/guest'
      end

      context "when mirroring the vagrant root" do
        it_behaves_like "creating a mirror class", 'C:/host','/var/guest'
        it_behaves_like "creating a guard listener", 'C:/host','/var/guest'
      end

      context "with two mirror pairs" do
        it_behaves_like "creating a mirror class", 'C:/host1','/var/guest1'
        it_behaves_like "creating a guard listener", 'C:/host1','/var/guest1'
        it_behaves_like "creating a mirror class", 'C:/host2','/var/guest2'
        it_behaves_like "creating a guard listener", 'C:/host2','/var/guest2'
      end

      context "with notifications in the queue" do
        it "synchronises the changes"
        it "waits for more notifications"
      end

      context "with no changes in the queue" do
        it "waits for new notifications"
        it "runs until signaled"
      end

      shared_examples "an orderly shutdown" do
        it "signals the TCP listener to quit"
        it "signals the Guard listener to quit"
        it "waits for the TCP listener to quit"
        it "waits for the Guard listener to quit"
        it "processes remaining jobs in the queue"
        it "calls the next middleware"
      end

      context "when signaled to quit" do
        it_behaves_like "an orderly shutdown"
      end

      context "when user presses q on the console" do
        it_behaves_like "an orderly shutdown"
      end
    end
  end
end