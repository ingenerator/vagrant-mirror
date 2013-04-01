# Executes rsync on the guest to update files between the shared folder and the local virtual disk.
# Propogates deletes if configured to do so, but not otherwise.
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    class Rsync
      attr_reader :vm
      attr_reader :guest_sf_path
      attr_reader :host_path
      attr_reader :delete
      attr_reader :excludes
      attr_reader :guest_path

      def initialize(vm, guest_sf_path, host_path, mirror_config)
        @vm = vm
        @guest_sf_path = guest_sf_path
        @host_path = host_path
        @delete = mirror_config[:delete]
        @excludes = mirror_config[:excludes]
        @guest_path = mirror_config[:guest_path]
      end

      def run(path)
        # Build the source and destination

      end

    end
  end
end