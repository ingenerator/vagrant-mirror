# Executes a full sync between the host and guest instance based on the configuration
# in the vagrantfile, copying new or changed files to the other side of the mirror.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Middleware
      class Sync

        # Creates an instance
        #
        # @param [Object] The next middleware in the chain
        # @param [Vagrant::Action::Environment] The environment
        def initialize(app, env)
          @app = app
          @env = env
        end

        # Executes the middleware and then continues to the next middleware in the
        # stack
        #
        # @param [Vagrant::Action::Environment] The environment
        def call(env)
          folders = env[:vm].config.mirror.folders
          if !folders.empty?
            synchronize(folders, env)
          else
            env[:ui].info("No vagrant-mirror mirrored folders configured for this box")
          end
          @app.call(env)
        end

        protected

        # Synchronizes the folder pairs configured in the vagrantfile
        #
        # @param [Array] The folder pairs to synchronise
        # @param [Vagrant::Action::Environment] The environment
        def synchronize(folders, env)
          ui = env[:ui]
          ui.info("Beginning directory synchronisation")

          connection = Vagrant::Mirror::Connection::SFTP.new(env[:vm], ui)

          folders.each do | folder |
            if folder[:host_path] == :vagrant_root
              host_path = env[:root_path]
            else
              host_path = folder[:host_path]
            end
            sync = Vagrant::Mirror::Sync::All.new(connection, host_path, folder[:guest_path], ui)
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