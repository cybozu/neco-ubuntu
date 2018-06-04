Ubuntu image customizer
=======================

This repository contains a Makefile to build a custom Ubuntu ISO installer
and a custom cloud image.  The cloud image are to be used with [placemat][]
and [placemat-menu] to prepare network boot servers in a virtual data center.

Prerequisites
-------------

The Makefile assumes to run on a recent Ubuntu or Debian OS.
To test built images, QEMU/KVM is used.

Build
-----

1. Prepare `setup/cluster.json` file.

    The contents should be a JSON array of objects with these fields:

    Name              | Type   | Description
    ----------------- | ------ | -----------
    `name`            | string | Cluster name
    `bastion_network` | string | IPv4 address of the bastion network
    `ntp_servers`     | array  | List of NTP server addresses

    This file will be read by `setup-neco-network`.
    An example of the file is available at `setup/cluster.json.example`.

1. Run `make` to see available build options.
1. Run `make setup`.  This is a one-time procedure.
1. Run `make all` to build everything.

* `build/cybozu-ubuntu-18.04-server-amd64.iso` is the custom ISO installer.
* `build/cybozu-ubuntu-18.04-server-cloudimg-amd64.img` is the custom cloud image.

Usage
-----

### Custom ISO installer

This installer is meant to setup a netboot service on a physical server.
Most installation options are preseeded; options need to be inputted manually are:

* Hostname
* Password for "cybozu" user.
* Storage partitioning
* Passphrase for LVM encryption.

### Custom cloud image

Use [cloud-init][] to configure your cloud instance.

### Setup after installation

1. Install `rkt`

    For cloud image installation, install `rkt` as follows.
    ISO installation did this automatically.

    ```console
    $ cd /extras
    $ sudo dpkg -i *.deb
    ```

2. Configure network

    Run `setup-neco-network` script as follows.
    This configures `systemd-networkd` for networking, `bird` for routing,
    and `chrony` for time adjustment.

    ```console
    $ cd /extas/setup
    $ sudo ./setup-neco-network RACK_NUMBER
    ```

3. Configure and run `sabakan` and `etcd`

    Run `setup-bootserver` script as follows.
    This configures [`sabakan`][sabakan], a distributed network boot service.
    Additionally, the script also configures `etcd` if the rack matches the
    given rack number on the command-line.

    ```console
    $ cd /extas/setup
    $ sudo ./setup-bootserver init RACK1 RACK2 RACK3 [RACK...]
    ```

### Notes

After setup, the system is configured as follows.

* Running `systemd-networkd` instead of `netplan.io`.  `netplan.io` is purged.
* Running `rkt` containers as systemd services.  Use `sudo rkt list` to get the list of them.
* The rack number of the server is stored in `/etc/neco/rack` file.
* The cluster ID of the server is stored in `/etc/neco/cluster` file.

License
-------

[MIT][]

[placemat]: https://github.com/cybozu-go/placemat
[placemat-menu]: https://github.com/cybozu-go/placemat-menu
[cloud-init]: https://cloudinit.readthedocs.io/
[sabakan]: https://github.com/cybozu-go/sabakan
[MIT]: https://opensource.org/licenses/MIT
