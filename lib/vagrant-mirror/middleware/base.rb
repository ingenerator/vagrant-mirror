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

        # Loads the rest of the middlewares first, then finishes up by running
        # our middleware. This is required because the core share_folders and
        # provision middlewares don not mount the shares until the very end of
        # the process and we need to run after that
        #
        # @param [Vagrant::Action::Environment] The environment
        def call(env)
          @app.call(env)

          mirrors = env[:vm].config.mirror.folders
          if !mirrors.empty?
            execute(mirrors, env)
          else
            env[:ui].info("No vagrant-mirror mirrored folders configured for this box")
          end
        end

        protected

        # Iterates over a set of mirror configs, fetching the paths for the shared folder pair from
        # on the guest and host and passing them together with the folder config to the passed block
        #
        # @param [Hash] The folder pair
        def each_mirror(mirrors)
          shared_folders = @env[:vm].config.vm.shared_folders

          if (mirrors.count > 1)
            raise Vagrant::Mirror::Errors::MultipleFoldersNotSupported.new("Sorry, vagrant-mirror doesn't support multiple base folders yet")
          end

          mirrors.each do | folder |
            # Locate the shared folder pairing in the config
            shared_folder = shared_folders[folder[:name]]

            if shared_folder.nil?
              raise Vagrant::Mirror::Errors::SharedFolderNotMapped.new("The folder #{folder[:name]} was not a valid Vagrant shared folder name")
            end

            # Pull out the guest and host path
            guest_path = shared_folder[:guestpath]
            host_path = File.expand_path(shared_folder[:hostpath], @env[:root_path])

            # Yield for the parent
            yield host_path, guest_path, folder
          end
        end

      end
    end
  end
end