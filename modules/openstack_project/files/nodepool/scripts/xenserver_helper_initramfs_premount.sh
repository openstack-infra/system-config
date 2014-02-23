#!/bin/sh -e

set -ex

PREREQ=""

# Output pre-requisites
prereqs()
{
        echo "$PREREQ"
}

case "$1" in
    prereqs)
        prereqs
        exit 0
        ;;
esac

. /scripts/functions

log_begin_msg "Resize started"
touch /etc/mtab

tune2fs -O ^has_journal /dev/xvda1
e2fsck -fp /dev/xvda1
resize2fs /dev/xvda1 4G

# Number of 4k blocks
NUMBER_OF_BLOCKS=$(tune2fs -l /dev/xvda1 | grep "Block count" | tr -d " " | cut -d":" -f 2)

# Convert them to 512 byte sectors
SIZE_OF_PARTITION=$(expr $NUMBER_OF_BLOCKS \* 8)

sfdisk -d /dev/xvda | sed -e "s,[0-9]\{8\},$SIZE_OF_PARTITION,g" > /tmp/new_layout

while !  cat /tmp/new_layout | sfdisk /dev/xvda; do
    sleep 1
done

while ! partprobe /dev/xvda; do
    sleep 1
done

tune2fs -j /dev/xvda1

sync

log_end_msg "Resize finished"
