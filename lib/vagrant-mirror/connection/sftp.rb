require 'net/sftp'

module Vagrant
  module Mirror
    module Connection
      class SFTP

        def initialize(vm, ui)
          @vm = vm
          @ui = ui
          @remote_stat_queue = Hash.new
          @local_stat_queue = Hash.new
        end

        def connect
          connection
        end

        # Queues a file or directory for upload to the guest and logs the transfer
        #
        # @param [string]  Host path to transfer
        # @param [string]  Guest path to upload to
        # @param [Time] Mtime to set on the uploaded file
        def upload(host_path, guest_path, mtime)
          connection.upload(host_path, guest_path, {:progress => self})
          remote_stat_queue(guest_path, { :mtime => mtime.to_i, :atime => Time.new.to_i })
          @ui.info(">> #{host_path}")
          return nil
        end

        # Queues a file or directory for download to the host and logs the transfer
        #
        # @param [string] Guest path to transfer
        # @param [string] Host path to transfer to
        # @param [Time] Mtime to set on the downloaded file
        def download(guest_path, host_path, mtime)
          connection.download(guest_path, host_path, {:progress => self})
          local_stat_queue(host_path, { :mtime => mtime.to_i })
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
          names = []
          begin
            connection.dir.entries(path).each do | entry |
              names << entry.name
            end
          rescue Net::SFTP::StatusException => e
            raise unless e.code == Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE
          end
          return names
        end

        # Removes a file or directory from the guest
        #
        # @param [string] Guest path to remove
        def delete(path)
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

        # Closes the SFTP connection
        def close
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


        # Updates remote or local mtime and related properties when transfer
        # of an individual file completes
        def on_close(transfer, file)

          if (transfer.is_a?(Net::SFTP::Operations::Upload))
            # Set the remote mtime
            stat = remote_stat_queue(file.remote)
            if !stat.nil?
              connection.setstat(file.remote, stat)
            end
          elsif (transfer.is_a?(Net::SFTP::Operations::Download))
            # Set the local mtime
            stat = local_stat_queue(file.local)
            if !stat.nil?
              # We can't set the mtime here because the file is still open, defer it 100ms
              Thread.new do
                sleep 0.1
                File.utime(stat[:mtime], stat[:mtime], file.local)
              end
            end
          else
            @ui.error("Unexpected transfer type passed to Vagrant::Mirror::Connection::SFTP.on_close")
          end
        end

        protected

        # Manages a queue of stats to apply to local files once transfers complete.
        # To push a stat onto the queue, call with file and stat arguments. To pop
        # a stat off, call with just a filename - the method will return nil if there
        # are no pending stats to apply.
        #
        # @param [String] Local filename
        # @param [Hash]   Hash of attributes to apply
        # @return [Hash]   Hash of attributes to apply
        def local_stat_queue(file, stat = nil)
          if stat.nil?
            # Accessor
            stat = @local_stat_queue.fetch(file, nil)
            if !stat.nil?
              @local_stat_queue.delete(file)
            end
            return stat
          else
            @local_stat_queue[file] = stat
          end
        end

        # Manages a queue of stats to apply to remote files once transfers complete.
        # To push a stat onto the queue, call with file and stat arguments. To pop
        # a stat off, call with just a filename - the method will return nil if there
        # are no pending stats to apply.
        #
        # @param [String] Remote filename
        # @param [Hash]   Hash of attributes to apply
        # @return [Hash]   Hash of attributes to apply
        def remote_stat_queue(file, stat = nil)
          if stat.nil?
            # Accessor
            stat = @remote_stat_queue.fetch(file, nil)
            if !stat.nil?
              @remote_stat_queue.delete(file)
            end
            return stat
          else
            @remote_stat_queue[file] = stat
          end
        end

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