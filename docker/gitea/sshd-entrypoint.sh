#!/bin/bash
set -e

# Generate host keys if necessary
/etc/s6/openssh/setup

exec "$@"
