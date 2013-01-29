# Manages a queue of stats to apply to local or remote files once
# transfers complete.
module Vagrant
  module Mirror
    module Connection
      module StatQueue
        class Local < Base

          protected

          # Apply the stat to a local file
          #
          # @param [String] The file to apply to
          # @param [Hash]   The stat to apply
          def setstat(file_path, stat)
            # We can't set the mtime here because the file is still open, defer it 100ms
            Thread.new do
              sleep 0.1
              File.utime(stat[:mtime], stat[:mtime], file_path)
            end
          end
        end
      end
    end
  end
end