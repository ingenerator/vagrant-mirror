# Manages a queue of stats to apply to local or remote files once
# transfers complete.
module Vagrant
  module Mirror
    module Connection
      module StatQueue
        class Base

          # Create the queue
          #
          # @param [Vagrant::Mirror::Connection::SFTP] The SFTP class
          def initialize(sftp)
            @queue = Hash.new
            @sftp = sftp
          end

          # Queue a stat to be applied later
          #
          # @param [String] The filename to apply to
          # @param [Hash]   The hash of stat attributes to apply
          def queue(file_path, stat)
            @queue[file_path] = stat
          end

          # Fetch a queued stat, or nil
          #
          # @param [String] The file to check
          # @return [Hash]  The queued stat
          def queued(file_path)
            @queue.fetch(file_path, nil)
          end

          # Apply the queued stat, if any
          #
          # @param [String] The file to apply to
          def apply(file_path)
            stat = queued(file_path)
            if !stat.nil?
              @queue.delete(file_path)
              setstat(file_path, stat)
            end
            return stat
          end

          protected

          # Apply the stat itself (implemented in descendants)
          #
          # @param [String] The file to apply to
          # @param [Hash]   The stat to apply
          def setstat(file_path, stat)
          end
        end
      end
    end
  end
end