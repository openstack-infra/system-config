#!/bin/bash -x
lvremove -f /dev/main/last_root
lvrename /dev/main/root last_root
lvcreate -L20G -s -n root /dev/main/orig_root
APPEND="$(cat /proc/cmdline)"
kexec -l /vmlinuz --initrd=/initrd.img --append="$APPEND"
nohup bash -c "sleep 2; kexec -e" </dev/null >/dev/null 2>&1 &
