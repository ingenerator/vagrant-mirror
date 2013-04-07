# Vagrant::Mirror

[![Build Status](https://travis-ci.org/ingenerator/vagrant-mirror.png)](https://travis-ci.org/ingenerator/vagrant-mirror)
[![Coverage Status](https://coveralls.io/repos/ingenerator/vagrant-mirror/badge.png?branch=master)](https://coveralls.io/r/ingenerator/vagrant-mirror)
[![Gem Version](https://badge.fury.io/rb/vagrant-mirror.png)](http://badge.fury.io/rb/vagrant-mirror)
[![Code Climate](https://codeclimate.com/github/ingenerator/vagrant-mirror.png)](https://codeclimate.com/github/ingenerator/vagrant-mirror)
[![Dependency Status](https://gemnasium.com/ingenerator/vagrant-mirror.png)](https://gemnasium.com/ingenerator/vagrant-mirror)

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

You need to install the plugin as a gem within Vagrant's embedded Ruby environment. You will
also require the appropriate listen filesystem driver to watch for changes. The plugin
currently only has an alpha release available, so you need to specify --pre on the install
command.

### On Windows

On Windows, the [WDM](https://github.com/Maher4Ever/wdm) driver is recommended. Install like
this:

```bash
# Add the Ruby devkit to the Vagrant environment so that native extensions can build
# If your vagrant install path is different you will need to edit this command
c:\vagrant\vagrant\embedded\devkitvars.bat

# Install the latest alpha release of the vagrant-mirror gem
vagrant gem install vagrant-mirror --pre

# Install the wdm gem
vagrant gem install wdm
```

### On Linux

Vagrant-mirror is not tested on a linux host - though in theory it should work (the
specs run on Travis and all pass, and listen is tested cross-platform). The 
[rb-inotify](https://github.com/nex3/rb-inotify) driver is recommended.

```bash
vagrant gem install vagrant-mirror --pre
vagrant gem install rb-inotify
```

If you have problems getting it working on linux, contributions are welcome.

### On OS X

Vagrant-mirror is not tested on OS X - though in theory it should work. The 
[rb-fsevent](https://github.com/thibaudgg/rb-fsevent) driver is recommended.

```bash
vagrant gem install vagrant-mirror --pre
vagrant gem install rb-inotify
```

## Basic usage

Include paths to mirror in your Vagrantfile like so:

```ruby
    # To mirror the vagrant root path
    config.mirror.vagrant_root "/guest/path"

    # To mirror any arbitrary path
    config.vm.share_folder "foo", "guest/share/path", "host/path"
    config.mirror.folder "foo", "/guest/mirror/path"
```

When you run `vagrant up` or `vagrant reload`, vagrant-mirror will:

* Ensure that your guest has any shared folders required for the pair
* Create any local symlinks required (see below)
* Run rsync on the guest to copy from the virtualbox shared folder to the local guest path
* Register with the local host filesystem for updates using using [listen](https://rubygems.org/gems/listen)

When changes are detected on the host, they will be notified by the listen gem. Once a change is
detected, the host will trigger the guest to run rsync on the changed path to update the locally
stored file.

If you want to force a full resync, you can run `vagrant mirror sync`.

If for some reason the mirror crashes you can just run `vagrant mirror monitor` on the host to bring
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

Under the hood, vagrant-mirror just uses rsync so if for some reason you want to update your
host with a bigger set of changed files from the guest (perhaps you ran a script that modified
your source code somehow) you can just SSH to the guest and run rsync to copy files from the 
mirror folder back to the virtualbox share.

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

By default, vagrant mirror sync transfers new files and folders but does not propogate deletes. 
This can lead to unwanted behaviour, in particular if your application on the guest indexes or 
autoloads all the files it finds. You can enable deletions with the following:

```ruby
    # To mirror the vagrant root path - the options hash is also available when sharing any folder
    config.mirror.vagrant_root "/guest/path", {
      :delete => true
    }
```

You should ensure that your "exclude" configuration includes all the paths that may be present on
the guest (build directories, cache, assets) as otherwise they will be deleted.

**Note that the :delete option only controls whether rsync will delete unexpected files during 
vagrant mirror sync. During active mirroring, if you delete a file on the host this will be
detected by listen and the file will be deleted on the guest.**

### Notifications

The time between updates is generally pretty fast, but it is nonzero. If you're working in fast
cycles it can be that you rerun a command on the guest before your updated files have been
transferred, which may be confusing. Avoid this by having vagrant-mirror issue a system beep whenever
transfers complete. Note that every so often vagrant will drop the SSH connection and the first
command on a new connection can take at least 4 seconds, subsequent commands should be significantly
faster.

```ruby
    # To mirror the vagrant root path - the options hash is also available when sharing any folder
    config.mirror.vagrant_root "/guest/path", {
      :beep => true
    }
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`) with specs. Changes without specs will 
   not be merged.
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Acknowledgements

The [vagrant-notify](https://github.com/fgrehm/vagrant-notify/) plugin was very useful in working
out how to structure this plugin. And of course, none of this would be possible without the great
work on vagrant itself, thanks to Mitchell for that.

## Copyright

Copyright (c) 2013 inGenerator Ltd. See LICENSE.txt for
further details.
