# Executes a full sync from the host to the guest instance based on the configuration
# in the vagrantfile, copying new or changed files to the guest as required.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Middleware
      class Sync < Base

        # Loads the rest of the middlewares first, then finishes up by running
        # the sync middleware. This is required because the core share_folders
        # middleware does not mount the shares until the very end of the process
        # and we need to run after that
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

        # Synchronizes the folder pairs configured in the vagrantfile
        #
        # @param [Array] The folder pairs to synchronise
        # @param [Vagrant::Action::Environment] The environment
        def execute(mirrors, env)
          ui = env[:ui]
          ui.info("Beginning directory synchronisation")

          begin
            each_mirror(mirrors) do | host_path, guest_sf_path, mirror_config |
              # Create any required symlinks
              mirror_config[:symlinks].each do | relpath |
                relpath.sub!(/^\//, '')
                source = "#{guest_sf_path}/#{relpath}"
                target = "#{mirror_config[:guest_path]}/#{relpath}"

                # Find the parent directory - we have to do this with regexp as we don't have the
                # right filesystem to use File.expand
                dirs = /^(.*)(\/.+)$/.match(target)
                if (dirs)
                  target_dir = dirs[1]
                else
                  target_dir = '/'
                end

                # Create the parent directory and create the symlink
                env[:vm].channel.sudo("mkdir -p #{target_dir} && ln -s #{source} #{target}")
              end

              # Trigger the sync on the remote host
              rsync = Vagrant::Mirror::Rsync.new(env[:vm], guest_sf_path, host_path, mirror_config)
              rsync.run('/')
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