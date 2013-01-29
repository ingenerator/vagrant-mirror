require "vagrant-mirror/connection/statqueue/shared_examples_for_statqueue.rb"

describe Vagrant::Mirror::Connection::StatQueue::Remote do

  let (:file) { '/foo/bar' }
  let (:stat) { { :mtime => 1358703212 } }
  let (:sftp) { double("Vagrant::Mirror::Connection::SFTP").as_null_object }

  subject { Vagrant::Mirror::Connection::StatQueue::Remote.new(sftp) }

  it_behaves_like "a stat queue"

  describe "#apply" do
    let (:connection) { double("Net::SFTP::Session").as_null_object }

    before (:each) do
      sftp.stub(:connect).and_return(connection)
    end

    context "when the file has a stat in the queue" do
      before (:each) do
        subject.queue(file, stat)
      end

      it "sets the file stat" do
        connection.should_receive(:setstat)
          .with(file, stat)

        subject.apply(file)
      end

      it "removes the stat from the queue" do
        connection.should_receive(:setstat)
          .once

        subject.apply(file)
        subject.apply(file)
      end
    end

    context "when the file has no stat queued" do
      it "does not set atime or mtime" do
        connection.should_not_recieve(:setstat)

        subject.apply(file)
      end
    end
  end
end