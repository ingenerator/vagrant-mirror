describe Vagrant::Mirror::Rsync do

  describe "#run" do
    context "when passed the root path" do
      it "rsyncs from the top level mirrored folders on the guest"
      it "excludes any configured exclude paths"

    end

    context "when passed a child path" do
      it "rsyncs from the child level mirrored path on the guest"
      it "excludes any configured exclude paths"
    end
  end
end