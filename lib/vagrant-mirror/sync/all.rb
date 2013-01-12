module Vagrant
  module Mirror
    module Sync
      class All < Base

        def execute(path)
          path = path.chomp('/')
          host_dir = host_path(path).chomp('/')
          guest_dir = guest_path(path).chomp('/')

          if !@connection.exists?(guest_dir)
            # This is the easy case, just let the connection handle recursion
            @connection.mkdir(guest_dir)
            @connection.upload!(host_dir, guest_dir, @ui)
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
            if File.directory?(host_file)
              puts "recurse to #{file}"
              execute(file)
            end

            # Transfer new/modified files between host and guest
            compare_and_transfer(host_file, guest_file)
          end

        end
      end
    end
  end
end