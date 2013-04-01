describe Vagrant::Mirror::Middleware::Sync do
  # Shared mocks
  let (:env)           { Vagrant::Action::Environment.new }
  let (:vm)            { double("Vagrant::VM").as_null_object }
  let (:ui)            { double("Vagrant::UI::Interface").as_null_object }
  let (:app)           { double("Object").as_null_object }
  let (:config)        { double("Object").as_null_object }
  let (:configmirror)  { double("Vagrant::Mirror::Config").as_null_object }

  # Set basic stubs for shared mocks
  before (:each) do
    env[:vm] = vm
    env[:ui] = ui

    vm.stub(:config).and_return config
    config.stub(:mirror).and_return configmirror

    app.stub(:call)

  end

  subject { Vagrant::Mirror::Middleware::Sync.new(app, env) }

  describe "#call" do

    shared_examples "chained middleware" do
      it "calls the next middleware" do
        app.should_receive(:call).with(env)

        subject.call(env)
      end
    end

    context "with no mirrored folders" do
      before (:each) do
        configmirror.stub(:folders).and_return([])
      end

      it_behaves_like "chained middleware"
    end

  end
end