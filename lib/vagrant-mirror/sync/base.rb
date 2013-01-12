# Base class for file sync actions, providing common required functionality
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    module Sync
      class Base

        # Initialises the synchroniser
        #
        # @param [Vagrant::Mirror::Connection::SFTP] The sftp connection instance
        # @param [String] The root path on the host to mirror
        # @param [String] The root path on the guest to mirror
        # @param [Vagrant::UI::Interface] The Vagrant UI class
        def initialize(connection, host_path, guest_path, ui)
          @connection = connection
          @host_root = host_path
          @guest_root = guest_path
          @ui = ui
        end

        # ==================================================================
        # Begin protected internal methods
        # ==================================================================
        protected

        # Gets the absolute host path for a file
        #
        # @param [String] Relative path to the file
        # @return [String] Absolute path to the file on the host
        def host_path(relative_path)
          File.join(@host_root, relative_path)
        end

        # Gets the absolute guest path for a file
        #
        # @param [String] Relative path to the file
        # @return [String] Absolute path to the file on the guest
        def guest_path(relative_path)
          File.join(@guest_root, relative_path)
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
          @connection.mtime(path)
        end

      end
    end
  end
end