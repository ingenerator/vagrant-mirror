# Compares the contents of the host and guest paths and transfers any
# missing or modified paths to the other side of the mirror. If a whole
# directory is missing, uses recursive upload/download from the SFTP class,
# otherwise it iterates over and compares the directory contents.
#
# This class does not detect deletions - if a file is missing on one side
# of the mirror it will simply be replaced.
#
# @author Andrew Coulton < andrew@ingenerator.com >
module Vagrant
  module Mirror
    module Sync
      class All < Base

        # Compares a folder between guest and host, transferring any new or
        # modified files in the right direction.
        #
        # @param [string] The base path to compare
        def execute(path)
          path = path.chomp('/')
          host_dir = host_path(path).chomp('/')
          guest_dir = guest_path(path).chomp('/')

          if !@connection.exists?(guest_dir)
            # This is the easy case, just let the connection handle recursion
            @connection.upload(host_dir, guest_dir, true)
            return
          end

          if !File.exists?(host_dir)
            # This is also easy, let the connection handle recursion
            @connection.download(guest_dir, host_dir, true)
            return
          end

          # If the guest path already exists, have to sync manually
          # First get a combined listing of the two paths
          all_files = @connection.dir_entries(guest_dir) | Dir.entries(host_dir)
          all_files.each do | file |
            # Ignore . and ..
            if (file == '.') or (file == '..')
              next
            end

            # Get local paths
            host_file = File.join(host_dir, file)
            guest_file = File.join(guest_dir, file)

            # Recurse for directories
            if File.directory?(host_file) \
               or ( !File.exists?(host_file) and @connection.directory?(guest_file))
              execute("#{path}/#{file}")
            end

            # Transfer new/modified files between host and guest
            compare_and_transfer(host_file, guest_file)
          end

        end
      end
    end
  end
end