#!/bin/sh

set -ue

SNAPSHOT=snapshot-$(date '+%Y%m%d_%H%M%S')
ETCD_PASSWD=$(cat /usr/local/etc/etcd-snapshot.passwd)

ETCDCTL_API=3 etcdctl --user backup:${ETCD_PASSWD} snapshot save /tmp/${SNAPSHOT}
tar --remove-files -cvzf /var/lib/etcd-snapshot/${SNAPSHOT}.tar.gz /tmp/${SNAPSHOT}

find /var/lib/etcd-snapshot/ -mtime 14 -exec rm -f {} \;