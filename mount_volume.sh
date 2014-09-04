#!/bin/bash

# Copyright 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Sigh. nova volume-attach is not immediate, but there is no status to track
sleep 120

if [ -b /dev/vdc ]; then
    DEV='/dev/vdc'
elif [ -b /dev/xvdb ]; then
    DEV='/dev/xvdb'
else
    echo "Could not mount volume"
    exit 1
fi
if ! blkid | grep $DEV | grep ext4 ; then
    mkfs.ext4 ${DEV}
fi
perl -nle "m,${DEV}, || print" -i /etc/fstab
if [ ! -d /srv ] ; then
    mkdir -p /srv
fi
echo "${DEV}  /srv  ext4  errors=remount-ro,barrier=0  0  2" >> /etc/fstab
mount -a
