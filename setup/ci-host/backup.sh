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

cd $WORKDIR

FOUND_VMS=`virsh --connect qemu:///system list | tr -s ' ' | cut -d ' ' -f3 | sed -e s/--$*//g | sed -e s/Name//g`
VM_TO_CP=`echo $FOUND_VMS | sed -e s%opencontrail\.org%%`

for j in $FOUND_VMS
do
	virsh --connect qemu:///system suspend $j
	PAUSED_VMS=`virsh --connect qemu:///system list | grep paused | wc -l`
	if [ $PAUSED_VMS -ne 1 ]; then 
		echo "Something fishy, cannot continue backup... !!"
		echo "Exiting... !!"
		exit 1
	fi
	
	BACKUP_IMAGE=`echo $j | sed -e s%opencontrail\.org%%`

	cp -v /var/lib/libvirt/images/$BACKUP_IMAGE*.opencontrail.org.vmdk $WORKDIR/"$BACKUP_IMAGE.opencontrail.org.vmdk-$date" >> /tmp/logs 
	gzip "$i-$date" 
	virsh --connect qemu:///system resume $j
done






