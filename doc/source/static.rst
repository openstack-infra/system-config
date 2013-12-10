:title: Static Web Hosting

.. _static:

Static Web Hosting
##################

Several virtual hosts serve static data from an Apache server on
static.openstack.org.

At a Glance
===========

:Hosts:
  * http://logs.openstack.org
  * http://docs-draft.openstack.org
  * http://status.openstack.org
  * http://pypi.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/static.pp`
:Projects:
  * http://apache.org/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci

Overview
========

Each apache vhost has a section in the puppet manifest for the static
host.  Some of the vhosts hold large amounts of data; Cinder volumes
and LVM are used to manage those.

Adding a New Device
===================

If the main volume group doesn't have enough space for what you want
to do, this is how you can add a new volume.

Log into ci-puppetmaster.openstack.org and run::

  . ~root/cinder-venv/bin/activate
  . ~root/ci-launch/cinder.sh

  nova list
  cinder list

* Add a new cinder volume (substitute the next number in series for
  NN)::

    cinder create --display-name "static.openstack.org/mainNN" 1024
    nova volume-attach <server id> <volume id> auto

* On static.openstack.org, create the partition table::

    DEVICE=/dev/xvdX
    sudo parted $DEVICE mklabel msdos mkpart primary 0% 100% set 1 lvm on
    sudo pvcreate ${DEVICE}1

* It should show up in pvs::

    $ sudo pvs
      PV         VG   Fmt  Attr PSize    PFree
      /dev/xvdX1      lvm2 a-   1024.00g 1024.00g

* Add it to the main volume group::

    sudo vgextend main ${DEVICE}1

Creating a New Logical Volume
=============================

Make sure there is enough space in the volume group::

  $ sudo vgs
    VG   #PV #LV #SN Attr   VSize VFree
    main   4   2   0 wz--n- 2.00t 347.98g

If not, see `Adding a New Device`_.

Create the new logical volume and initialize the filesystem::

  NAME=newvolumename
  sudo lvcreate -L1500GB -n $NAME main

  sudo mkfs.ext4 -m 0 -j -L $NAME /dev/main/$NAME
  sudo tune2fs -i 0 -c 0 /dev/main/$NAME

Be sure to add it to ``/etc/fstab``.

Expanding an Existing Logical Volume
====================================

Make sure there is enough space in the volume group::

  $ sudo vgs
    VG   #PV #LV #SN Attr   VSize VFree
    main   4   2   0 wz--n- 2.00t 347.98g

If not, see `Adding a New Device`_.

The following example to increase the size of a volume by 100G is
untested; please confirm::

  NAME=volumename
  sudo lvextend -L+100G /dev/main/$NAME
  sudo resize2fs /dev/main/$NAME
