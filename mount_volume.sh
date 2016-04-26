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

DEVICE=$1
MOUNT_PATH=$2
FS_LABEL=$3

# Because images may not have all the things we need.
if which apt-get ; then
    apt-get update && apt-get install -y lvm2
elif which yum ; then
    yum -y install lvm2
fi

# Sanity check that we don't break anything that already has an fs.
if ! blkid | grep $DEVICE ; then
    set -e
    parted --script $DEVICE mklabel msdos mkpart primary 0% 100% set 1 lvm on
    partprobe -s $DEVICE
    pvcreate ${DEVICE}1
    vgcreate main ${DEVICE}1
    lvcreate -l 100%FREE -n $FS_LABEL main
    mkfs.ext4 -m 0 -j -L $FS_LABEL /dev/main/$FS_LABEL
    tune2fs -i 0 -c 0 /dev/main/$FS_LABEL

    # Remove existing fstab entries for this device.
    perl -nle "m,/dev/main/$FS_LABEL, || print" -i /etc/fstab

    if [ ! -d $MOUNT_PATH ] ; then
        mkdir -p $MOUNT_PATH
    fi

    echo "/dev/main/$FS_LABEL  $MOUNT_PATH  ext4  errors=remount-ro,barrier=0  0  2" >> /etc/fstab
    mount -a
else
    exit 1
fi
