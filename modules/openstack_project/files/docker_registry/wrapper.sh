#!/bin/bash

# Verify k5start is running
if killall -0 k5start 2>/dev/null; then
  echo "k5start already running"
else
  /usr/bin/k5start -b -K 60 -f /etc/docker.keytab service/docker
fi

exec /usr/bin/docker-registry "$@"
