# Base middleware with common functionality.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Middleware
      class Base

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
          mirrors = env[:vm].config.mirror.folders
          if !mirrors.empty?
            execute(mirrors, env)
          else
            env[:ui].info("No vagrant-mirror mirrored folders configured for this box")
          end
          @app.call(env)
        end

        protected

        # Iterates over a set of mirror configs Fetches the host path from a pair of folders, converting the :vagrant_root
        # symbol to be the path on disk
        #
        # @param [Hash] The folder pair
        # @return [String] The absolute host path for the folder
        def each_mirror(mirrors)
          mirrors.each do | folders |
            if folders[:host_path] == :vagrant_root
              host_path = @env[:root_path]
            else
              host_path = folders[:host_path]
            end

            yield host_path, folders[:guest_path]
          end
        end

        # Builds a Vagrant::Mirror::Connection::SFTP to the VM
        #
        # @return [Vagrant::Mirror::Connection::SFTP]
        def vm_sftp
          Vagrant::Mirror::Connection::SFTP.new(@env[:vm], @env[:ui])
        end

      end
    end
  end
end