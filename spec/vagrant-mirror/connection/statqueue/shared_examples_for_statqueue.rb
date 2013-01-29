shared_examples "a stat queue" do
  describe "#queue" do
    it "adds the file to the queue" do
      subject.queue(file, stat)

      subject.queued(file).should eq stat
    end
  end

  describe "#queued" do
    context "when the file is queued" do
      before (:each) do
        subject.queue(file, stat)
      end

      it "should return the stat" do
        subject.queued(file).should eq stat
      end
    end

    context "when the queue is empty" do
      it "should be nil" do
        subject.queued(file).should be_nil
      end
    end

    context "when other files are queued" do
      before (:each) do
        subject.queue(file, stat)
      end

      it "should be nil" do
        subject.queued('/some/other/file').should be_nil
      end
    end
  end
end