#!/bin/bash

#=======================================================================================
#title           : backup.sh
#description     : This script will backup VMs used for CI host on ubuntu-precise 12043.
#author          : Vinay Mahuli
#date            : 09-July-2014
#version         : 0.1
#usage           : ./backup.sh
#notes           : NA
#=======================================================================================

isRoot=`whoami | cut -f1`
if [ $isRoot != root ]; then
        echo -e "\n You need to be root !!\n"
        exit 1
fi

DISTR=`cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d '=' -f2`
if [ $DISTR != precise ]; then
        echo -e "\n This utility is only meant for Ubuntu Precise 12043 !!\n"
        exit 1
fi

date=`date +"%d-%m-%y"` 

WORKDIR="/tmp/workdir_$$"
mkdir -p $WORKDIR

cd /var/lib/libvirt/images && FOUND=`find . -type f | grep vmdk | grep -v bkup` 
cd $WORKDIR

FOUND_VMS=`virsh --connect qemu:///system list | tr -s ' ' | cut -d ' ' -f3 | sed -e s/--$*//g | sed -e s/Name//g`

for j in $FOUND_VMS
do
	virsh --connect qemu:///system suspend $j
done

for i in $FOUND 
do 
	cp -v /var/lib/libvirt/images/$i $WORKDIR/"$i-$date" >> /tmp/logs 
	gzip "$i-$date" 
done






