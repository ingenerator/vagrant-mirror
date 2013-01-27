# Processes notified file additions, modifications and deletions notified by
# guard/listen, and replays them on the other side of the mirror.
# The execute method will be called for each changeset notified whether
# by guard or over the TCP socket (from guard on the guest). This could
# cause a race condition as changes on the guest trigger changes on the host
# and vice versa.
#
# Therefore, on notification of added or modified file, the class just
# syncs whichever is the newest file between the two machines. On deletion
# it will quietly fail if the file it is notified of has already been
# deleted.
#
# @author Andrew Coulton < andrew@ingenerator.com >
module Vagrant
  module Mirror
    module Sync
      class Changes < Base

        # Compares a single notified changeset and transfers any changed,
        # modified or removed files in the right direction.
        #
        # @param [Symbol] Which side of the mirror the change was detected
        # @param [Array] Array of added paths
        # @param [Array] Array of changed paths
        # @param [Array] Array of removed paths
        def execute(source, added, modified, removed)

          # Combine added and modified, they're the same for our purposes
          changed = added + modified
          changed.each do |file|
            # Transfer the newest file to the other side, or do nothing
            compare_and_transfer(host_path(file), guest_path(file))
          end

          # Process deleted files
          removed.each do |file|
            # Expect a cascade - only delete on opposite side if exists
            if source == :host
              guest_file = guest_path(file)
              if !guest_mtime(guest_file).nil?
                @connection.delete(guest_file)
              else
                @ui.info("#{file} was not found on guest - nothing to delete")
              end
            elsif source == :guest
              host_file = host_path(file)
              if File.exists?(host_file)
                File.delete(host_file)
              else
                @ui.info("#{file} was not found on host - nothing to delete")
              end
            end
          end

          # Complete all transfers
          @connection.finish_transfers
        end
      end
    end
  end
end