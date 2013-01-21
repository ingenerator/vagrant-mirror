require 'optparse'

# Command line tasks to run a full synchronisation of the mirrored folders,
# or to restart the live mirror (for example, if it fails). Folder mirroring
# will also be started with vagrant up and vagrant resume
module Vagrant
  module Mirror
    class Command < Vagrant::Command::Base

      # Initializes the command and parses the subcommands from argv
      def initialize(argv, env)
        super
        @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
      end

      # Run the command - valid commands are:
      # - vagrant mirror sync
      # - vagrant mirror monitor
      def execute

        if @main_args.include?("-h") || @main_args.include?("--help")
          # Print the help for all the box commands.
          return help
        end

        # Currently we can only work with a single VM environment
        raise Errors::SingleVMEnvironmentRequired if @env.multivm?

        # Run the appropriate subcommand
        case @sub_command
          when 'sync'
            return execute_sync
          when 'monitor'
            return execute_monitor
          when nil
            return execute_monitor
          else
            return help
        end
      end

      protected

      # Execute the Sync middleware on the primary vm
      def execute_sync
        @env.primary_vm.run_action(Vagrant::Mirror::Middleware::Sync)
      end

      # Execute the GuestInstall and Mirror middlewares on the primary vm
      def execute_monitor
        @env.primary_vm.run_action(Vagrant::Mirror::Middleware::GuestInstall)
        @env.primary_vm.run_action(Vagrant::Mirror::Middleware::Mirror)
      end

      # Output help documentation
      def help
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant mirror <command> [<args>]"
          opts.separator ""
          opts.separator "Available subcommands:"
          opts.separator "     sync     One-off synchronisation of all mirrored files"
          opts.separator "     monitor  Monitor and mirror changes on host and guest"
          opts.separator ""
          opts.separator "For help on any individual command run `vagrant mirror COMMAND -h`"
        end

        @env.ui.info(opts.help, :prefix => false)
      end

    end
  end
end