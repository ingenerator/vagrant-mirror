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
                    # Ignore files that match the configured exclude paths
                    if exclude?(change[:path], mirror_config)
                      next
                    end

                    # Handle removed files first - guard sometimes flagged as deleted when they aren't
                    # So we first check if the file has been deleted on the host. If so, we delete on
                    # the guest, otherwise we add to the list to rsync in case there are changes
                    if (change[:event] == :removed)
                      unless File.exists?(File.join(host_path, change[:path]))
                        # Delete the file on the guest
                        target = "#{mirror_config[:guest_path]}/#{change[:path]}"
                        ui.warn("XX Deleting #{target}")
                        env[:vm].channel.sudo("rm #{target}")

                        # Beep if configured
                        if (mirror_config[:beep])
                          print "\a"
                        end

                        # Move to the next file
                        next
                      end
                    end

                    # Otherwise, run rsync on the file
                    ui.info(">> #{change[:path]}")
                    rsync.run(change[:path])

                    # Beep if configured
                    if (mirror_config[:beep])
                      print "\a"
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

        # Checks whether a given path should be excluded based on the :exclude config for this mirror
        #
        # @param [String] The file path being processed
        # @param [Hash]   The mirror config options
        #
        # @return [Bool]  Whether to exclude this file
        def exclude?(path, mirror_config)
          compiled_excludes = mirror_config.fetch(:compiled_excludes, {})
          excluded = false

          mirror_config[:exclude].each do | exclude |
            # Check if it has been compiled
            unless compiled_excludes.has_key? exclude
              compiled_excludes[exclude] = compile_exclude(exclude)
            end
            exclude = compiled_excludes[exclude]

            # Test for a match against the path
            if exclude.match(path)
              excluded = true
              break
            end
          end

          # Return the result
          excluded
        end

        # Mirrors the folder pairs configured in the vagrantfile
        #
        # @param [String] A glob-style exclude format
        #
        # @return [Regexp] The exclude path as a regex
        def compile_exclude(exclude)
          exclude = exclude.dup

          # Absolute path is tied to start of string, relative to any directory separator
          if exclude.chars.first == '/'
            regex = "^"
            exclude[0] = ''
          else
            regex = "(^|/)"
          end

          # Temporarily convert wildcards to placeholders
          exclude.gsub!('**','<<globwild2>>')
          exclude.gsub!('*','<<globwild>>')

          # Escape the string for regexp characters
          exclude = Regexp.escape(exclude)


          # one star matches anything except directories
          exclude.gsub!('<<globwild>>', '[^/]*?')

          # two stars match anything including directories
          exclude.gsub!('<<globwild2>>','.*?')

          regex << exclude

          # pattern should always end on a directory separator or end of string
          regex << '($|/)'

          Regexp.new(regex)
        end
      end
    end
  end
end