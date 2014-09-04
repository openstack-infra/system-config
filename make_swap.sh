#!/bin/bash

# Copyright 2013 OpenStack Foundation
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

# If we're running on a cloud server with no swap, fix that:
if [ `grep SwapTotal /proc/meminfo | awk '{ print $2; }'` -eq 0 ]; then
    if [ -b /dev/vdb ]; then
        DEV='/dev/vdb'
    elif [ -b /dev/xvde ]; then
        DEV='/dev/xvde'
    fi
    if [ -n "$DEV" ]; then
        MEMKB=`grep MemTotal /proc/meminfo | awk '{print $2; }'`
        # Use the nearest power of two in MB as the swap size.
        # This ensures that the partitions below are aligned properly.
        MEM=`python -c "import math ; print 2**int(round(math.log($MEMKB/1024, 2)))"`
        umount ${DEV}
        parted ${DEV} --script -- mklabel msdos
        parted ${DEV} --script -- mkpart primary linux-swap 1 ${MEM}
        parted ${DEV} --script -- mkpart primary ext2 ${MEM} -1
        mkswap ${DEV}1
        mkfs.ext4 ${DEV}2
        swapon ${DEV}1
        mount ${DEV}2 /mnt
        rsync -a /opt/ /mnt/
        umount /mnt
        perl -nle "m,${DEV}, || print" -i /etc/fstab
        echo "${DEV}1  none  swap  sw                           0  0" >> /etc/fstab
        echo "${DEV}2  /opt  ext4  errors=remount-ro,barrier=0  0  2" >> /etc/fstab
        mount -a
    fi
fi
