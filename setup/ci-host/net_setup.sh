#!/usr/bin/env bash

brctl addbr br0
brctl addbr br1

ifconfig br0 promisc up
ifconfig br1 promisc up

ip addr add 148.251.110.30/28 dev br0
ip addr add 192.168.1.1/24 dev br1

# scp zuul:/etc/default/grub /etc/default/grub && scp zuul:/etc/init/ttyS0.conf /etc/init/. && update-grub
