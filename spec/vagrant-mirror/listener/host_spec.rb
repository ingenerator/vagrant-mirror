describe Vagrant::Mirror::Listener::Host do

  let (:queue) { double("Queue").as_null_object }

  before (:each) do
    Listen.stub(:to).as_null_object
  end

  describe "#listen!" do

    subject { Vagrant::Mirror::Listener::Host.new('c:/host', queue) }

    it "listens to the host directory" do
      Listen.should_receive(:to).with('c:/host', anything())

      subject.listen!
    end

    it "requests relative paths" do
      Listen.should_receive(:to)
        .with(anything(), hash_including( :relative_paths => true ))

      subject.listen!
    end

    context "when changes received" do
      before(:each) do
        Listen.stub(:to)
          .and_yield(['modified1','modified2'],[],[])
          .and_yield([],['added1','added2'],[])
          .and_yield([],[],['removed1','removed2'])
          .and_yield(['modified3'],['added3'],['removed3'])
      end

      it "pushes added files onto the queue one by one" do
        queue.should_receive(:"<<")
          .with(hash_including({:event => :added, :path => 'added1'}))
        queue.should_receive(:"<<")
          .with(hash_including({:event => :added, :path => 'added2'}))

        subject.listen!
      end

      it "pushes modified files onto the queue one by one" do
        queue.should_receive(:"<<")
          .with(hash_including({:event => :modified, :path => 'modified1'}))
        queue.should_receive(:"<<")
          .with(hash_including({:event => :modified, :path => 'modified2'}))

        subject.listen!
      end

      it "pushes removed files onto the queue one by one" do
        queue.should_receive(:"<<")
          .with(hash_including({:event => :removed, :path => 'removed1'}))
        queue.should_receive(:"<<")
          .with(hash_including({:event => :removed, :path => 'removed2'}))

        subject.listen!
      end

      it "handles simultaneous changes" do
        queue.should_receive(:"<<")
          .with(hash_including({:event => :added, :path => 'added3'}))
        queue.should_receive(:"<<")
          .with(hash_including({:event => :modified, :path => 'modified3'}))
        queue.should_receive(:"<<")
          .with(hash_including({:event => :removed, :path => 'removed3'}))

        subject.listen!
      end

    end

    context "with a close signal" do
      it "stops listening"
    end
  end

  describe "#listen" do

    subject { Vagrant::Mirror::Listener::Host.new('c:/host', queue) }

    let (:thread) { double("Thread") }

    before (:each) do
      Thread.stub(:new).and_yield.and_return(thread)
    end

    it "starts a new thread" do
      Thread.should_receive(:new)

      subject.listen
    end

    it "runs listen! in the new thread" do
      Listen.should_receive(:to)

      subject.listen
    end

    it "returns the thread" do
      subject.listen.should eq thread
    end
  end
end