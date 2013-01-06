# Vagrant::Mirror

[![Build Status](https://travis-ci.org/ingenerator/vagrant-mirror.png)](https://travis-ci.org/ingenerator/vagrant-mirror)

A vagrant plugin that mirrors a folder between the host and guest, designed to get around the performance 
issues of virtualbox shared folders and the headaches of NFS or Samba shares with a windows host and linux 
guest. Tested with Windows XP and Vista hosts and Ubuntu 12.04 guest. However, it uses the [listen](https://rubygems.org/gems/listen)
gem from guard so it should be fully cross-platform.

## Installation

The best option is to install the gem (note you will need to run `vagrant gem vagrant-mirror` if using the 
bundled Vagrant package as this runs in isolation from your global ruby installation).

You can then add to your Vagrantfile like so:

```ruby
    require 'vagrant-mirror'
    
    Vagrant::Config.run do | config |
      #.....
    end
```

Alternatively, add this repository alongside the Vagrantfile and require the library manually.

## Usage

Include paths to mirror in your Vagrantfile like so:

```ruby
    # To mirror the vagrant root path
    config.mirror.vagrant_root "/guest/path"
    
    # To mirror any arbitrary path
    config.mirror.folders "/guest/path", "/host/path"
```

When you run `vagrant up` or `vagrant resume`, vagrant-mirror will:

* Synchronise the host with the guest, transferring any missing or modified files by SCP
* Register with the local host and guest filesystems for updates using [listen](https://rubygems.org/gems/listen)
* Establish communication between guest and host using a Ruby [TCPServer](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/socket/rdoc/TCPServer.html) on host port `8082`

When changes are detected on the guest, they will be notified to the host over the TCP socket. When changes are
detected on the host, they will be notified by the listen gem. Once a change is detected, the host will compare
the last modified time and update the newer file to the guest or host as appropriate over SCP.

If your host IP changes, you will need to run `vagrant provision` to update the guest with the new IP.

If you want to force a full resync, you can run `vagrant mirror-sync`.

If for some reason the mirror crashes you can just run `vagrant-mirror monitor` on either side to bring it back up.

In case you need to run the notification server on a different port, you can set
it from your `Vagrantfile`:

    config.mirror.server_port = 8888

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`) with specs
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Acknowledgements

The [vagrant-notify](https://github.com/fgrehm/vagrant-notify/) plugin was very useful in working out how to structure this plugin.

## Copyright

Copyright (c) 2013 inGenerator Ltd. See LICENSE.txt for
further details.
