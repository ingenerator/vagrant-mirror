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
          .and_yield(['modified'],[],[])
          .and_yield([],['added'],[])
          .and_yield([],[],['removed'])
          .and_yield(['modified1'],['added1'],['removed1'])
      end

      it "pushes added files onto the queue" do
        queue.should_receive(:"<<")
          .with(hash_including(:added => ['added']))

        subject.listen!
      end

      it "pushes modified files onto the queue" do
        queue.should_receive(:"<<")
          .with(hash_including(:modified => ['modified']))

        subject.listen!
      end

      it "pushes removed files onto the queue" do
        queue.should_receive(:"<<")
          .with(hash_including(:removed => ['removed']))

        subject.listen!
      end

      it "handles simultaneous changes" do
        queue.should_receive(:"<<")
          .with(hash_including({
            :added => ['added1'],
            :modified => ['modified1'],
            :removed => ['removed1']
            }))

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