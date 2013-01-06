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
      
      # TCP port on the host that the server should listen for notifications from the guest on. Defaults to 8082.
      # @return [Integer] the port number
      def server_port
        if @server_port.nil?
          return 8082
        end
        @server_port
      end
      
      # TCP port on the host that the server should listen for notifications from the guest on. Defaults to 8082 if not set.
      # @param [Integer] the port number
      def server_port=(server_port)
        @server_port = server_port
      end
      
      # Validates the provided configuration
      # @param [Vagrant::Environemnt] Vagrant environment instance
      # @param [Vagrant::Config::ErrorRecorder] Stack of errors in configuration
      def validate(env, errors)
        errors.add("vagrant-mirror.server_port must be a valid port number") if !server_port.is_a? Integer
        folders.each do | folder |
          errors.add("vagrant-mirror cannot mirror an empty or nil host path") if (folder[:host_path].nil? || folder[:host_path].empty?)
          errors.add("vagrant-mirror cannot mirror an empty or nil guest path") if (folder[:guest_path].nil? || folder[:guest_path].empty?)
        end
      end
      
      # Shortcut to mirror the Vagrant root folder (where the Vagrantfile is stored) to a path on the guest
      # @param [String] Path on the guest to mirror to
      def vagrant_root(guest_path)
        folder(:vagrant_root, guest_path)
      end
      
      # Mirror a folder between the host and the guest
      # @param [String] Path on the host to mirror
      # @param [String] Path on the guest to mirror
      def folder(host_path, guest_path)
        @folders << {
          :host_path  => host_path,
          :guest_path => guest_path}
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