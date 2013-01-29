require "vagrant-mirror/connection/statqueue/shared_examples_for_statqueue.rb"

describe Vagrant::Mirror::Connection::StatQueue::Local do

  let (:file) { 'c:/foo/bar' }
  let (:stat) { { :mtime => 1358703212 } }
  let (:sftp) { double("Vagrant::Mirror::Connection::SFTP").as_null_object }

  subject { Vagrant::Mirror::Connection::StatQueue::Local.new(sftp) }

  it_behaves_like "a stat queue"

  describe "#apply" do

    before (:each) do
      Thread.stub(:new).and_yield
      File.stub(:utime).as_null_object
    end

    context "when the file has a stat in the queue" do
      before (:each) do
        subject.queue(file, stat)
      end

      it "sets the file atime to the queued mtime" do
        File.should_receive(:utime)
          .with(stat[:mtime], anything(), file)

        subject.apply(file)
      end

      it "sets the file mtime to the queued mtime" do
        File.should_receive(:utime)
          .with(anything(), stat[:mtime], file)

        subject.apply(file)
      end

      it "removes the stat from the queue" do
        subject.apply(file)

        File.should_not_receive(:utime)
        subject.apply(file)
      end
    end

    context "when the file has no stat queued" do
      it "does not set atime or mtime" do
        File.should_not_receive(:utime)

        subject.apply(file)
      end
    end
  end
end