# Monitors changes on the host and guest instance, and propogates any new, changed
# or deleted files between machines. Note that this will block the vagrant
# execution on the host.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Middleware
      class Mirror < Base

        # Loads the rest of the middlewares first, then finishes up by running
        # the mirror middleware. This allows the listener to start after the
        # instance has been provisioned.
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

        # Mirrors the folder pairs configured in the vagrantfile
        #
        # @param [Array] The folder pairs to synchronise
        # @param [Vagrant::Action::Environment] The environment
        def execute(mirrors, env)
          ui = env[:ui]
          ui.info("Beginning directory mirroring")

          begin
            workers = []

            # Create a thread to work off the queue for each folder
            each_mirror(mirrors) do | host_path, guest_sf_path, mirror_config |
              workers << Thread.new do
                # Set up the listener and the changes queue
                Thread.current["queue"] = Queue.new
                host_listener = Vagrant::Mirror::Listener::Host.new(host_path, Thread.current["queue"])
                rsync = Vagrant::Mirror::Rsync.new(env[:vm], guest_sf_path, host_path, mirror_config)

                # Start listening and store the thread reference
                Thread.current["listener"] = host_listener.listen

                # Just poll indefinitely waiting for changes or to be told to quit
                quit = false
                while !quit
                  change = Thread.current["queue"].pop
                  if (change[:quit])
                    quit = true
                  else
                    # Handle removed files first - guard sometimes flagged as deleted when they aren't
                    # So we first check if the file has been deleted on the host. If so, we delete on
                    # the guest, otherwise we add to the list to rsync in case there are changes
                    changes = []
                    change[:removed].each do | relpath |
                      if (File.exists?(File.join(host_path, relpath)))
                        changes << relpath
                      else
                        target = "#{mirror_config[:guest_path]}/#{relpath}"
                        ui.warn("XX Deleting #{target}")
                        env[:vm].channel.sudo("rm #{target}")
                      end
                    end

                    # Add to the list of deletions with each of the modified and added files
                    changes = changes + change[:added] + change[:modified]
                    changes.each do | relpath |
                      rsync.run(relpath)
                    end
                  end
                end
              end
            end

            # Wait for the listener thread to exit
            workers.each do | thread |
              thread.join
            end
          rescue RuntimeError => e
            # Pass through Vagrant errors
            if e.is_a? Vagrant::Errors::VagrantError
              raise
            end

            # Convert to a vagrant error descendant so that the box is not cleaned up
            raise Vagrant::Mirror::Errors::Error.new("Vagrant-mirror caught a #{e.class.name} - #{e.message}")
          end

          ui.success("Completed directory synchronisation")
        end

      end
    end
  end
end