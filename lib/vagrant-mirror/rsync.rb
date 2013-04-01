# Executes rsync on the guest to update files between the shared folder and the local virtual disk.
# Propogates deletes if configured to do so, but not otherwise.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    class Rsync
      # @return [Vagrant::VM] The VM to mirror on
      attr_reader :vm

      # @return [String] The path to the virtualbox shared folder on the guest
      attr_reader :guest_sf_path

      # @return [String] The path to the virtualbox shared folder on the host
      attr_reader :host_path

      # @return [Bool] Whether Rsync should delete unexpected files
      attr_reader :delete

      # @return [Array] The array of paths to exclude
      attr_reader :excludes

      # @return [String] The exclude paths formatted as an array of rsync exclude arguments
      attr_reader :exclude_args

      # @return [String] The path to the mirror folder on the guest
      attr_reader :guest_path

      # Creates an instance
      #
      # @param [Vagrant::VM] The VM to mirror on
      # @param [String]      The path of the shared folder on the guest to use as the rsync source
      # @param [String]      The path of the shared folder on the host - used to check whether a path is a directory
      # @param [Hash]        The config.mirror options hash with the guest mirror destination, delete, etc
      def initialize(vm, guest_sf_path, host_path, mirror_config)
        @vm = vm
        @guest_sf_path = guest_sf_path
        @host_path = host_path
        @delete = mirror_config[:delete]
        @excludes = mirror_config[:exclude]
        @guest_path = mirror_config[:guest_path]

        # Build the exclude argument array
        @exclude_args = []
        if (@excludes.count > 0)
          @excludes.each do | exclude |
            exclude_args << "--exclude '#{exclude}'"
          end
        end
      end

      # Run rsync on the guest to update a path - either the whole mirror directory or individual
      # files and folders within it.
      #
      # @param [String] The path to run in
      def run(path)
        # Strip a leading / off the path to avoid any problems
        path.sub!(/^\//, '')

        # Build the source and destination paths
        source = "#{guest_sf_path}/#{path}"
        dest = "#{guest_path}/#{path}"

        # Check if the source is a directory on the host - if so, add a / for rsync
        if ((path != '') && (File.directory?(File.join(host_path, path))))
          source << '/'
          dest << '/'
        end


        # Build the rsync command
        args = ['rsync -av']

        if (delete)
          args << '--del'
        end

        args = args + exclude_args

        args << source
        args << dest

        cmd = args.join(' ')

        # Run rsync
        vm.channel.sudo(cmd)
      end

    end
  end
end