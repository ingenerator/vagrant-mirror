require 'net/ssh'

# Synchronises a single file between host and guest, transferring whichever is the newer file
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    class FileSynchroniser

      # Initialises the synchroniser
      #
      # @param [Net::SSH::Connection::Session] The SSH connection to the guest
      # @param [String] The root path on the host to mirror
      # @param [String] The root path on the guest to mirror
      def initialize(ssh, host_path, guest_path)
        @ssh = ssh
        @host_root = host_path
        @guest_root = guest_path
      end

      # Gets the absolute host and guest paths for a file
      # 
      # @param [String] Relative path to the file
      # @return [Hash] A hash of :guest and :host paths
      def absolute_paths(relative_path)
        { :host  => File.join(@host_root, relative_path),
          :guest => File.join(@guest_root, relative_path)}
      end

      # Gets the mtime of a file on the host from an absolute path
      #
      # @param [String] Absolute host path
      # @return [Time] mtime, or nil if the file does not exist
      def host_mtime(path)
        if !File.exists?(path)
          return nil
        end
        return File.mtime(path)
      end

      # Gets the mtime of a file on the guest from an absolute path
      #
      # @param [String] Absolute guest path
      # @return [Time] mtime, or nil if the file does not exist
      def guest_mtime(path)
        stat = @ssh.exec!("stat -c %Y #{path}")
        if stat.is_a? Numeric
          return Time.at(stat)
        end

        nil
      end

      # An initial full sync of a directory structure - uses recursive SCP
      # if possible (ie the directory does not exist on the destination).
      # Blocks until complete.
      def sync_everything!()
      end

      # Syncs a file which has been added or modified, updating the other
      # side if it is out of date
      def sync_added()
      end

      # Syncs a file which has been deleted, updating the other side if it
      # is out of date
      def sync_deleted()
      end

    end
  end
end