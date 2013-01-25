describe Vagrant::Mirror::Command do
  let (:argv) { []  }
  let (:env)  { double("Vagrant::Environment").as_null_object }
  let (:vm)   { double("Vagrant::VM").as_null_object }
  let (:ui)   { double("Vagrant::UI::Interface").as_null_object }

  before (:each) do
    env.stub(:primary_vm).and_return vm
    env.stub(:multivm?).and_return false
    env.stub(:ui).and_return ui
  end

  subject { Vagrant::Mirror::Command.new(argv, env) }

  describe "#execute" do
    shared_examples "cannot run in multivm" do
      before (:each) do
        env.stub(:multivm?).and_return(true)
      end

      it "throws a SingleVMEnvironmentRequired error" do
        expect { subject.execute }.to raise_error(Vagrant::Mirror::Errors::SingleVMEnvironmentRequired)
      end
    end

    context "with vagrant mirror sync" do
      let (:argv) { ['sync' ] }

      it_behaves_like "cannot run in multivm"

      it "runs the sync middleware with primary vm" do
        vm.should_receive(:run_action).with(Vagrant::Mirror::Middleware::Sync)

        subject.execute
      end

    end

    shared_examples "the monitor command" do
      it "runs the guestinstall middleware with primary vm" do
        vm.should_receive(:run_action).with(Vagrant::Mirror::Middleware::GuestInstall)

        subject.execute
      end
      it "runs the monitor middleware with primary vm" do
        vm.should_receive(:run_action).with(Vagrant::Mirror::Middleware::Mirror)

        subject.execute
      end
    end

    context "with vagrant mirror monitor" do
      let (:argv) { ['monitor' ] }

      it_behaves_like "cannot run in multivm"
      it_behaves_like "the monitor command"
    end

    context "with an empty command" do
      let (:argv) { [] }

      it_behaves_like "cannot run in multivm"
      it_behaves_like "the monitor command"
    end

    shared_examples "the help command" do
      it "prints valid usage" do
        ui.should_receive(:info).with(/monitor/, anything())

        subject.execute
      end

      it "does not run anything" do
        ui.stub(:info)
        vm.should_not_receive(:run_action)

        subject.execute
      end
    end

    context "with unknown command" do
      let (:argv) { ['nothing'] }

      it_behaves_like "cannot run in multivm"
      it_behaves_like "the help command"
    end

    context "with help command" do
      let (:argv) { ['-h', 'monitor'] }

      it_behaves_like "the help command"
    end

  end
end