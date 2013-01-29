# Manages a queue of stats to apply to local or remote files once
# transfers complete.
module Vagrant
  module Mirror
    module Connection
      module StatQueue
        class Remote < Base

          protected

          # Apply the stat to a remote file
          #
          # @param [String] The file to apply to
          # @param [Hash]   The stat to apply
          def setstat(file, stat)
            @sftp.connect.setstat(file, stat)
          end
        end
      end
    end
  end
end