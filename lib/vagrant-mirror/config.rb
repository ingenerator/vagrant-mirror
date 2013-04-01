# Holds configuration for the vagrant-mirror plugin
#
# @author Andrew Coulton < andrew@ingerator.com >
module Vagrant
  module Mirror
    class Config < Vagrant::Config::Base

      # @return [Array] An array of hashes holding the details of folders to monitor
      attr_reader   :folders

      def initialize
        @folders = []
      end

      # Validates the provided configuration
      # @param [Vagrant::Environment] Vagrant environment instance
      # @param [Vagrant::Config::ErrorRecorder] Stack of errors in configuration
      def validate(env, errors)
        folders.each do | folder |
          errors.add("vagrant-mirror cannot mirror an empty or nil host path") if (folder[:name].nil? || folder[:name].empty?)
          errors.add("vagrant-mirror cannot mirror an empty or nil guest path") if (folder[:guest_path].nil? || folder[:guest_path].empty?)
          valid_opts = [:name, :guest_path, :delete, :beep, :exclude, :symlinks]
          folder.each do | option, value |
            errors.add("vagrant-mirror does not understand the option #{option}") unless valid_opts.include?(option)
          end
        end
      end

      # Shortcut to mirror the Vagrant root folder (where the Vagrantfile is stored) to a path on the guest
      # @param [String] Path on the guest to mirror to
      # @param [Hash]   Command options - see README.md for details
      def vagrant_root(guest_path, options = {} )
        folder('v-root', guest_path, options)
      end

      # Mirror a folder between the host and the guest
      # @param [String] Name of the shared folder to mirror as passed to the vagrant shared folder config
      # @param [String] Path on the guest to mirror to
      # @param [Hash]   Command options - see README.md for details
      def folder(share_name, guest_path, options = {} )
        # Add the default options
        folder = {
          :delete   => false,
          :beep     => false,
          :exclude  => [],
          :symlinks => []
        }.merge(options)

        # If there are any symlinks, they need to be added to the rsync excludes
        folder[:symlinks].each do | link_path |
          folder[:exclude] << link_path
        end

        # Add the names to the hash
        folder[:name] = share_name
        folder[:guest_path] = guest_path

        # Store the folder details
        @folders << folder
      end

      # Custom merge method since some keys here are merged differently.
      # @param [Vagrant::Mirror::Config] Configuration to merge with this one
      # @return [Vagrant::Mirror::Config] A new config instance with the merged configuration
      def merge(other)
        result = super
        result.instance_variable_set(:@folders, @folders + other.folders)
        result
      end

    end
  end
end