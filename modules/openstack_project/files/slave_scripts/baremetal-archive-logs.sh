#!/bin/bash -xe

for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    cp /var/log/orchestra/rsyslog/$host/syslog $WORKSPACE/logs/$host-syslog.txt
done
