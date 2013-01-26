# Monitors changes on the host and guest instance, and propogates any new, changed
# or deleted files between machines. Note that this will block the vagrant
# execution on the host.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Middleware
      class Mirror

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
            mirror(folders, env)
          else
            env[:ui].info("No vagrant-mirror mirrored folders configured for this box")
          end
          @app.call(env)
        end

        protected

        # Mirrors the folder pairs configured in the vagrantfile
        #
        # @param [Array] The folder pairs to synchronise
        # @param [Vagrant::Action::Environment] The environment
        def mirror(folders, env)
          ui = env[:ui]
          ui.info("Beginning directory mirroring")

          connection = Vagrant::Mirror::Connection::SFTP.new(env[:vm], ui)
          threads = []

          folders.each do | folder |
            # Create a new main thread to poll for changes on each folder pairing
            threads << Thread.new do
              if folder[:host_path] == :vagrant_root
                host_path = env[:root_path]
              else
                host_path = folder[:host_path]
              end

              sync = Vagrant::Mirror::Sync::Changes.new(connection, host_path, folder[:guest_path], ui)
              Thread.current["queue"] = Queue.new
              host_listener = Vagrant::Mirror::Listen::Host.new(host_path, Thread.current["queue"])

              Thread.current["host_listener_thread"] = host_listener.listen

              # Just poll indefinitely waiting for changes or to be told to quit
              quit = false
              while !quit
                change = Thread.current["queue"].pop
                if (change[:quit])
                  quit = true
                else
                  sync.execute(change[:source], change[:added], change[:modified], change[:removed])
                end
              end
            end
          end

          # Wait for the threads to exit
          threads.each do | thread |
            thread.join
          end

          ui.success("Completed directory synchronisation")
        end

      end
    end
  end
end