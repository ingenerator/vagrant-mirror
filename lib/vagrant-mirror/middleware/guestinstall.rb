module Vagrant
  module Mirror
    module Middleware
      class GuestInstall

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
            #mirror(folders, env)
          else
            env[:ui].info("No vagrant-mirror mirrored folders configured for this box")
          end
          @app.call(env)
        end

      end
    end
  end
end