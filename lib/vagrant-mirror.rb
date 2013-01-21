require 'vagrant'

require 'vagrant-mirror/errors'
require 'vagrant-mirror/version'
require 'vagrant-mirror/config'

# Require the sync tasks
require 'vagrant-mirror/sync/base'
require 'vagrant-mirror/sync/changes'
require 'vagrant-mirror/sync/all'

# Require all the listeners for now, for specs
require 'vagrant-mirror/listen/guest'
require 'vagrant-mirror/listen/host'
require 'vagrant-mirror/listen/tcp'

# Require the connection
require 'vagrant-mirror/connection/sftp'

# Require the middlewares
require 'vagrant-mirror/middleware/guestinstall'
require 'vagrant-mirror/middleware/sync'
require 'vagrant-mirror/middleware/mirror'

# Require the command
require 'vagrant-mirror/command'
