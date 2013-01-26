# Executes a full sync between the host and guest instance based on the configuration
# in the vagrantfile, copying new or changed files to the other side of the mirror.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Middleware
      class Sync < Base

        protected

        # Synchronizes the folder pairs configured in the vagrantfile
        #
        # @param [Array] The folder pairs to synchronise
        # @param [Vagrant::Action::Environment] The environment
        def execute(mirrors, env)
          ui = env[:ui]
          ui.info("Beginning directory synchronisation")

          connection = vm_sftp()

          each_mirror(mirrors) do | host_path, guest_path |
            sync = Vagrant::Mirror::Sync::All.new(connection, host_path, guest_path, ui)
            sync.execute("/")
          end

          connection.finish_transfers
          connection.close
          ui.success("Completed directory synchronisation")
        end

      end
    end
  end
end