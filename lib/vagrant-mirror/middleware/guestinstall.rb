module Vagrant
  module Mirror
    module Middleware
      class GuestInstall < Base

      protected

        # Synchronizes the folder pairs configured in the vagrantfile
        #
        # @param [Array] The folder pairs to synchronise
        # @param [Vagrant::Action::Environment] The environment
        def execute(mirrors, env)
        end
      end
    end
  end
end