require 'net/sftp'

module Vagrant
  module Mirror
    module Connection
      class SFTP

        def initialize(vm, ui)
          @vm = vm
          @ui = ui
        end

        def connect
          connection
        end

        # Queues a file or directory for upload to the guest and logs the transfer
        #
        # @param [string] Host path to transfer
        # @param [string] Guest path to upload to
        def upload(host_path, guest_path)
          connection.upload(host_path, guest_path, :progress => self)
          @ui.info(">> #{host_path}")
          return nil
        end

        # Queues a file or directory for download to the host and logs the transfer
        #
        # @param [string] Guest path to transfer
        # @param [string] Host path to transfer to
        def download(guest_path, host_path)
          connection.download(guest_path, host_path, :progress => self)
          @ui.info("<< #{guest_path}")
          return nil
        end

        # Checks whether a path exists on the guest and returns true or false
        #
        # @param [string] Guest path to check
        # @return [boolean] Whether the path exists
        def exists?(path)
          begin
            connection.stat!(path)
            return true
          rescue Net::SFTP::StatusException => e
            raise unless e.code == Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE
          end
          return false
        end

        # Returns the mtime of a path on the guest, or returns nil if not existing
        #
        # @param [string] Guest path to check
        # @return [Time]  The mtime
        def mtime(path)
          begin
            mtime = connection.stat!(path).mtime
            return Time.at(mtime)
          rescue Net::SFTP::StatusException => e
            raise unless e.code == Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE
          end
          return nil
        end

        # Checks whether a given path on the guest is an existing directory
        #
        # @param [string] Guest path to check
        # @return [boolean] True for a directory, false for file or not found, nil if unknown
        def directory?(path)
          begin
            return connection.stat!(path).directory?
          rescue Net::SFTP::StatusException => e
            raise unless e.code == Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE
          end
          return false
        end

        # Creates a directory on the guest
        #
        # @param [string] Guest path to create
        def mkdir(path)
          connection.mkdir(path)
          return nil
        end

        # Gets the contents of a directory on the guest as an array
        #
        # @param [string] Guest path to list
        # @return [array] The contents of the directory
        def dir_entries(path)
          connection.dir.entries(path)
        end

        # Removes a file or directory from the guest
        #
        # @param [string] Guest path to remove
        def unlink(path)
          if directory?(path)
            connection.rmdir(path)
            @ui.warn("XX #{path}")
          else
            connection.remove(path)
            @ui.warn("xx #{path}")
          end
          return nil
        end

        # Waits for any pending SFTP transfers to complete
        def finish_transfers
          connection.loop
        end

        # Upload/Download progress callback - only logs when all pending
        # transfers have completed
        #
        # @param [Object] The uploader or downloader object
        def on_finish(transfer)
          if !connection.pending_requests.any?
            @ui.info("All transfers completed")
          end
        end

        protected

        # Creates and returns a persistent SFTP connection to the guest
        # @return [Net::SFTP::Session] A persistent SFTP connection
        def connection

          if @connection && !@connection.closed?
            # Vagrant tries to send data over the socket here but this would
            # have to be blocking and hit performance - need to come
            # up with a better way to check the socket actually open?
            return @connection
          end

          # Get the vm connection options
          ssh_info = @vm.ssh.info

          # Build the SSH connection options
          opts = {
            :port                  => ssh_info[:port],
            :keys                  => [ssh_info[:private_key_path]],
            :keys_only             => true,
            :user_known_hosts_file => [],
            :paranoid              => false,
            :config                => false,
            :forward_agent         => ssh_info[:forward_agent]
          }

          # Connect to SFTP
          connection = Net::SFTP.start(ssh_info[:host], ssh_info[:username], opts)

          @connection = connection
        end

      end
    end
  end
end