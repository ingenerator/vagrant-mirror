require 'vagrant'

require 'vagrant-mirror/errors'
require 'vagrant-mirror/version'
require 'vagrant-mirror/config'

# Require the host listener
require 'vagrant-mirror/listener/host'

# Require the middlewares
require 'vagrant-mirror/middleware/base'
require 'vagrant-mirror/middleware/sync'
require 'vagrant-mirror/middleware/mirror'

# Require the command
require 'vagrant-mirror/command'

# Register the config
Vagrant.config_keys.register(:mirror) { Vagrant::Mirror::Config }

# Register the command
Vagrant.commands.register(:mirror) { Vagrant::Mirror::Command }

# Add the sync middleware to the start stack
Vagrant.actions[:start].use Vagrant::Mirror::Middleware::Sync

# Add the mirror middleware to the standard stacks
Vagrant.actions[:start].insert Vagrant::Action::VM::Provision, Vagrant::Mirror::Middleware::Mirror

# Abort on unhandled exceptions in any thread
Thread.abort_on_exception = true