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

1. Prepare [etcdpasswd][] repository.

    You may create a symlink to an existing `etcdpasswd` directory, or
    clone it as follows:

    ```console
    $ git clone https://github.com/cybozu-go/etcdpasswd
    ```

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

    ```console
    $ cd /extras/setup
    $ sudo ./setup-rkt
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
    This configures [`sabakan`][sabakan], a distributed network boot service,
    and [`etcdpasswd`][etcdpasswd], a distributed user/group management service.

    Additionally, the script also configures `etcd` and `etcd-backup` if the
    rack matches the given rack number on the command-line.

    ```console
    $ cd /extas/setup
    $ sudo ./setup-bootserver init RACK1 RACK2 RACK3 [RACK...]
    sabakan etcd password: yyyy
    backup etcd password: zzzz
    etcdpasswd etcd password: qqqq
    ```

    As shown, `setup-bootserver` asks passwords.  This will be used for etcd
    authentication.  The first password is for `sabakan` user of etcd, the
    second is for `backup`, and the third is for `etcdpasswd`.  If you want
    to enable etcd authentication, run `setup-etcd-user` script as follows:

    ```console
    $ cd /extras/setup
    $ sudo ./setup-etcd-user
    root password: xxxx
    sabakan password: yyyy
    backup password: zzzz
    etcdpasswd password: qqqq
    ```

    Note that passwords given to `setup-etcd-user` should be the same as
    those given to `setup-bootserver`.
    Be warned that these passwords should be kept securely.

### Notes

After setup, the system is configured as follows.

* etcd authentication is *not* enabled.
* Running `systemd-networkd` instead of `netplan.io`.  `netplan.io` is purged.
* Running `rkt` containers as systemd services.  Use `sudo rkt list` to get the list of them.
* `etcd-backup.service` is kicked by systemd.timer once an hour. It gets a snapshot from etcd.
* Running `ep-agent.service` to synchronize users and groups.
* The rack number of the server is stored in `/etc/neco/rack` file.
* The cluster ID of the server is stored in `/etc/neco/cluster` file.

License
-------

[MIT][]

[placemat]: https://github.com/cybozu-go/placemat
[placemat-menu]: https://github.com/cybozu-go/placemat-menu
[cloud-init]: https://cloudinit.readthedocs.io/
[sabakan]: https://github.com/cybozu-go/sabakan
[etcdpasswd]: https://github.com/cybozu-go/etcdpasswd
[MIT]: https://opensource.org/licenses/MIT
