# Monitors changes on the host and guest instance, and propogates any new, changed
# or deleted files between machines. Note that this will block the vagrant
# execution on the host.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Middleware
      class Mirror < Base

        protected

        # Mirrors the folder pairs configured in the vagrantfile
        #
        # @param [Array] The folder pairs to synchronise
        # @param [Vagrant::Action::Environment] The environment
        def execute(mirrors, env)
          ui = env[:ui]
          ui.info("Beginning directory mirroring")

          connection = vm_sftp()
          threads = []

          each_mirror(mirrors) do | host_path, guest_path |
            # Create a new main thread to poll for changes on each folder pairing
            threads << Thread.new do

              sync = Vagrant::Mirror::Sync::Changes.new(connection, host_path, guest_path, ui)
              Thread.current["queue"] = Queue.new
              host_listener = Vagrant::Mirror::Listener::Host.new(host_path, Thread.current["queue"])

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