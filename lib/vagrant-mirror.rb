require 'vagrant'

require 'vagrant-mirror/errors'
require 'vagrant-mirror/version'
require 'vagrant-mirror/config'

# Require the sync tasks
require 'vagrant-mirror/sync/base'
require 'vagrant-mirror/sync/changes'
require 'vagrant-mirror/sync/all'

# Require all the listeners for now, for specs
require 'vagrant-mirror/listener/guest'
require 'vagrant-mirror/listener/host'
require 'vagrant-mirror/listener/tcp'

# Require the connection
require 'vagrant-mirror/connection/sftp'

# Require the middlewares
require 'vagrant-mirror/middleware/base'
require 'vagrant-mirror/middleware/guestinstall'
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