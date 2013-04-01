# Vagrant::Mirror

[![Build Status](https://travis-ci.org/ingenerator/vagrant-mirror.png)](https://travis-ci.org/ingenerator/vagrant-mirror)

**This plugin is for the 1.0.x series of Vagrant and has not been updated to work with 1.1 and
above. We plan to update it eventually, if you want it faster than that then contributions are
welcome!**

A vagrant plugin that mirrors a folder from host to guest, designed to get around the performance
issues of virtualbox shared folders and the headaches of NFS or Samba shares with a windows host and
linux guest. Tested with Windows XP and Vista hosts and Ubuntu 12.04 guest. However, it uses the
[listen](https://rubygems.org/gems/listen) gem from guard so it should be fully cross-platform. Your
guest will need to have rsync installed.

Vagrant-mirror runs on top of existing virtualbox shared folders, using rsync to mirror from the
shared folder to a local instance folder. This seems to be best for performance and limits the
number of dependencies.

## Installation

The best option is to install the gem (note you will need to run `vagrant gem vagrant-mirror` if
using the bundled Vagrant package as this runs in isolation from your global ruby installation).

You also need to install the correct filesystem driver for your host operating system:

* For Windows - [WDM](https://github.com/Maher4Ever/wdm)
* For Linux - [rb-inotify](https://github.com/nex3/rb-inotify)
* For OS X - [rb-fsevent](https://github.com/thibaudgg/rb-fsevent)

Unfortunately there is currently no way to specify these as platform-specific dependencies in the
gemfile.

You can then add to your Vagrantfile like so:

```ruby
    require 'vagrant-mirror'

    Vagrant::Config.run do | config |
      #.....
    end
```

Alternatively, add this repository alongside the Vagrantfile and require the library manually.

## Basic usage

Include paths to mirror in your Vagrantfile like so:

```ruby
    # To mirror the vagrant root path
    config.mirror.vagrant_root "/guest/path"

    # To mirror any arbitrary path
    config.vm.share_folder "foo", "guest/share/path", "host/path"
    config.mirror.folder "foo", "/guest/mirror/path"
```

When you run `vagrant up` or `vagrant resume`, vagrant-mirror will:

* Ensure that your guest has any shared folders required for the pair
* Create any local symlinks required
* Run rsync on the guest to copy from the virtualbox shared folder to the local guest path
* Register with the local host filesystem for updates using using [listen](https://rubygems.org/gems/listen)

When changes are detected on the host, they will be notified by the listen gem. Once a change is
detected, the host will trigger the guest to run rsync on the changed path to update the locally
stored file.

If you want to force a full resync, you can run `vagrant mirror-sync`.

If for some reason the mirror crashes you can just run `vagrant-mirror monitor` on the host to bring
it back up.

## Advanced usage

### Mixing mirrored and shared files

Perhaps there are a few files or directories on the guest that you do want to appear on the host
too? Vagrant-mirror can create symbolic links for these from your mirror back to the virtualbox
shared folder. For example, perhaps you want the 'log' directory to work as though it were just on
the virtualbox shared folder?

```ruby
    # To mirror the vagrant root path - the options hash is also available when sharing any folder
    config.mirror.vagrant_root "/guest/path", {
      :symlinks => [ "/log"]
    }
```

This will exclude the "/log" folder from rsync and symlink it directly to the shared folder.

### Excluding paths

Perhaps there are paths you don't require on your virtual machine. For example, syncing your docs
folder might waste performance. You can easily add paths that should be excluded from mirroring:

```ruby
    # To mirror the vagrant root path - the options hash is also available when sharing any folder
    config.mirror.vagrant_root "/guest/path", {
      :exclude => [ "/docs"]
    }
```

You can use any valid rsync exclude patterns for this option. All paths should be specified relative
to the directory being mirrored.

### Propogating deletes

By default, vagrant mirror transfers new files and folders but does not propogate deletes. This can
lead to unwanted behaviour, in particular if your application on the guest indexes or autoloads all
the files it finds. You can enable deletions with the following:

```ruby
    # To mirror the vagrant root path - the options hash is also available when sharing any folder
    config.mirror.vagrant_root "/guest/path", {
      :delete => true
    }
```

You should ensure that your "exclude" configuration includes all the paths that may be present on
the guest (build directories, cache, assets) as otherwise they will be deleted.

### Notifications

The time between updates is generally pretty fast, but it is nonzero. If you're working in fast
cycles it can be that you rerun a command on the guest before your updated files have been
transferred, which may be confusing. Avoid this by having vagrant-mirror issue a system beep whenever
transfers complete.

```ruby
    # To mirror the vagrant root path - the options hash is also available when sharing any folder
    config.mirror.vagrant_root "/guest/path", {
      :beep => true
    }
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`) with specs
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Acknowledgements

The [vagrant-notify](https://github.com/fgrehm/vagrant-notify/) plugin was very useful in working
out how to structure this plugin.

## Copyright

Copyright (c) 2013 inGenerator Ltd. See LICENSE.txt for
further details.
