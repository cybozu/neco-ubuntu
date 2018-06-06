#!/bin/sh

set -ue

SNAPSHOT=snapshot-$(date '+%Y%m%d_%H%M%S')
ETCD_PASSWD=$(cat /usr/local/etc/etcd-snapshot.passwd)

uuid=$(rkt list --no-legend | awk '{if ($4 == "running" && $2 == "etcd") print $1}')

rkt enter --app=etcd $uuid etcdctl --user backup:${ETCD_PASSWD} snapshot save /var/lib/etcd/${SNAPSHOT}
tar --remove-files -cvzf /var/lib/etcd-snapshot/${SNAPSHOT}.tar.gz /var/lib/etcd-container/${SNAPSHOT}

find /var/lib/etcd-snapshot/ -mtime 14 -exec rm -f {} \;