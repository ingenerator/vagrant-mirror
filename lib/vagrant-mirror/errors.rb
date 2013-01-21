module Vagrant
  module Mirror
    module Errors
      class SingleVMEnvironmentRequired < Vagrant::Errors::VagrantError
        status_code(99)

        def initialize()
          message = "Vagrant-mirror currently only supports a single VM environment"
          super
        end
      end
    end
  end
end