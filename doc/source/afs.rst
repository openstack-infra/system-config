:title: OpenAFS

.. _openafs:

OpenAFS
#######

The Andrew Filesystem (or AFS) is a global distributed filesystem.
With a single mountpoint, clients can access any site on the Internet
which is running AFS as if it were a local filesystem.

OpenAFS is an open source implementation of the AFS services and
utilities.

A collection of AFS servers and volumes that are collectively
administered within a site is called a ``cell``.  The OpenStack
project runs the ``openstack.org`` AFS cell, accessible at
``/afs/openstack.org/``.

At a Glance
===========

:Hosts:
  * afsdb01.openstack.org (a vldb and pts server in DFW)
  * afsdb02.openstack.org (a vldb and pts server in ORD)
  * afs01.dfw.openstack.org (a fileserver in DFW)
  * afs02.dfw.openstack.org (a second fileserver in DFW)
  * afs01.ord.openstack.org (a fileserver in ORD)
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-openafs/tree/
  * :file:`modules/openstack_project/manifests/afsdb.pp`
  * :file:`modules/openstack_project/manifests/afsfs.pp`
:Projects:
  * http://openafs.org/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * http://rt.central.org/rt/Search/Results.html?Order=ASC&DefaultQueue=10&Query=Queue%20%3D%20%27openafs-bugs%27%20AND%20%28Status%20%3D%20%27open%27%20OR%20Status%20%3D%20%27new%27%29&Rows=50&OrderBy=id&Page=1&Format=&user=guest&pass=guest
:Resources:
  * `OpenAFS Documentation <http://docs.openafs.org/index.html>`_

OpenStack Cell
--------------

AFS may be one of the most thoroughly documented systems in the world.
There is plenty of very good information about how AFS works and the
commands to use it.  This document will only cover the mininmum needed
to understand our deployment of it.

OpenStack runs an AFS cell called ``openstack.org``.  There are three
important services provided by a cell: the volume location database
(VLDB), the protection database (PTS), and the file server (FS).  The
volume location service answers queries from clients about which
fileservers should be contacted to access particular volumes, while
the protection service provides information about users and groups.

Our implementation follows the common recommendation to colocate the
VLDB and PTS servers, and so they both run on our afsdb* servers.
These servers all have the same information and communicate with each
other to keep in sync and automatically provide high-availability
service.  For that reason, one of our DB servers is in the DFW region,
and the other in ORD.

Fileservers contain volumes, each of which is a portion of the file
space provided by that cell.  A volume appears as at least one
directory, but may contain directories within the volume.  Volumes are
mounted within other volumes to construct the filesystem hierarchy of
the cell.

OpenStack has two fileservers in DFW and one in ORD.  They do not
automatically contain copies of the same data.  A read-write volume in
AFS can only exist on exactly one fileserver, and if that fileserver
is out of service, the volumes it serves are not available.  However,
volumes may have read-write copies which are stored on other
fileservers.  If a client requests a read-only volume, as long as one
site with a read-only volume is online, it will be available.

Client Configuration
--------------------

To use OpenAFS on a Debian or Ubuntu machine::

  sudo apt-get install openafs-client openafs-krb5 krb5-user

Debconf will ask you for a default realm, cell and cache size.
Answer::

  Default Kerberos version 5 realm: OPENSTACK.ORG
  AFS cell this workstation belongs to: openstack.org
  Size of AFS cache in kB: 500000

The default cache size in debconf is 50000 (50MB) which is not very
large.  We recommend setting it to 500000 (500MB -- add a zero to the
default debconf value), or whatever is appropriate for your system.

The OpenAFS client is not started by default, so you will need to
run::

  sudo service openafs-client start

When it's done, you should be able to ``cd /afs/openstack.org``.

Most of what is in our AFS cell does not require authentication.
However, if you have a principal in kerberos, you can get an
authentication token for use with AFS with::

  kinit
  aklog

Administration
--------------

The following information is relevant to AFS administrators.

All of these commands have excellent manpages which can be accessed
with commands like ``man vos`` or ``man vos create``.  They also
provide short help messages when run like ``vos -help`` or ``vos
create -help``.

For all administrative commands, you may either run them from any AFS
client machine while authenticated as an AFS admin, or locally without
authentication on an AFS server machine by appending the `-localauth`
flag to the end of the command.

Adding a User
~~~~~~~~~~~~~
First, add a kerberos principal as described in :ref:`addprinc`.  Have the
username and UID from puppet ready.

Then add the user to the protection database with::

  pts createuser $USERNAME -id UID

Admin UIDs start at 1 and increment.  If you are adding a new admin
user, you must run ``pts listentries``, find the highest UID for an
admin user, increment it by one and use that as the UID.  The username
for an admin user should be in the form ``username.admin``.

.. note::
  Any '/' characters in a kerberos principal become '.' characters in
  AFS.

Adding a Superuser
~~~~~~~~~~~~~~~~~~
Run the following commands to add an existing principal to AFS as a
superuser::

  bos adduser -server afsdb01.openstack.org -user $USERNAME.admin
  bos adduser -server afsdb02.openstack.org -user $USERNAME.admin
  bos adduser -server afs01.dfw.openstack.org -user $USERNAME.admin
  bos adduser -server afs02.dfw.openstack.org -user $USERNAME.admin
  bos adduser -server afs01.ord.openstack.org -user $USERNAME.admin
  pts adduser -user $USERNAME.admin -group system:administrators

Creating a Volume
~~~~~~~~~~~~~~~~~

Select a fileserver for the read-write copy of the volume according to
which region you wish to locate it after ensuring it has sufficient
free space.  Then run::

  vos create $FILESERVER a $VOLUMENAME

The `a` in the preceding command tells it to place the volume on
partition `vicepa`.  Our fileservers only have one partition and therefore
this is a constant.

Be sure to mount the read-write volume in AFS with::

  fs mkmount /afs/.openstack.org/path/to/mountpoint $VOLUMENAME

You may want to create read-only sites for the volume with ``vos
addsite`` and then ``vos release``.

You should set the volume quota with ``fs setquota``.

Adding a Fileserver
~~~~~~~~~~~~~~~~~~~
Put the machine's public IP on a single line in
/var/lib/openafs/local/NetInfo (TODO: puppet this).

Copy ``/etc/openafs/server/*`` from an existing fileserver.

Create an LVM volume named ``vicepa`` from cinder volumes.  See
:ref:`cinder` for details on volume management.  Then run::

  mkdir /vicepa
  echo "/dev/main/vicepa  /vicepa ext4  errors=remount-ro,barrier=0  0  2" >>/etc/fstab
  mount -a

Finally, create the fileserver with::

  bos create NEWSERVER dafs dafs \
    -cmd "/usr/lib/openafs/dafileserver -p 23 -busyat 600 -rxpck 400 -s 1200 -l  1200 -cb 65535 -b 240 -vc 1200" \
    -cmd /usr/lib/openafs/davolserver \
    -cmd /usr/lib/openafs/salvageserver \
    -cmd /usr/lib/openafs/dasalvager

Mirrors
~~~~~~~

We host mirrors in AFS so that we store only one copy of the data, but
mirror servers local to each cloud region in which we operate serve
that data to nearby hosts from their local cache.

All of our mirrors are housed under ``/afs/openstack.org/mirror``.
Each mirror is on its own volume, and each with a read-only replica.
This allows mirrors to be updated and then the read-only replicas
atomically updated.  Because mirrors are typically very large and
replication across regions is slow, we place both copies of mirror
data on two fileservers in the same region.  This allows us to perform
maintenance on fileservers hosting mirror data as well deal with
outages related to a single server, but does not protect the mirror
system from a region-wide outage.

In order to establish a new mirror, do the following:

* Create the mirror volume.  See `Creating a Volume`_ for details.
  The volume should be named ``mirror.foo``, where `foo` is
  descriptive of the contents of the mirror.  Example::

    vos create afs01.dfw.openstack.org a mirror.foo

* Create read-only replicas of the volume.  One replica should be
  located on the same fileserver (it will take little to no additional
  space), and at least one other replica on a different fileserver.
  Example::

    vos addsite afs01.dfw.openstack.org a mirror.foo
    vos addsite afs02.dfw.openstack.org a mirror.foo

* Release the read-only replicas::

    vos release mirror.foo

  See the status of all volumes with::

    vos listvldb

When traversing from a read-only volume to another volume across a
mountpoint, AFS will first attempt to use a read-only replica of the
destination volume if one exists.  In order to naturally cause clients
to prefer our read-only paths for mirrors, the entire path up to that
point is composed of read-only volumes::

  /afs             [root.afs]
    /openstack.org [root.cell]
      /mirror      [mirror]
        /bar       [mirror.bar]

In order to mount the mirror.foo volume under ``mirror`` we need to
modify the read-write version of the ``mirror`` volume.  To make this
easy, the read-write version of the cell root is mounted at
``/afs/.openstack.org``.  Folllowing the same logic from earlier,
traversing to paths below that mount point will generally prefer
read-write volumes.

* Mount the volume into afs using the read-write path::

    fs mkmount /afs/.openstack.org/mirror/foo mirror.foo

* Release the ``mirror`` volume so that the (currently empty) foo
  mirror itself appears in directory listings under
  ``/afs/openstack.org/mirror``::

    vos release mirror

* Create a principal for the mirror update process.  See
  :ref:`addprinc` for details.  The principal should be called
  ``service/foo-mirror``.  Example::

    kadmin: addprinc -randkey service/foo-mirror@OPENSTACK.ORG
    kadmin: ktadd -k /path/to/foo.keytab service/foo-mirror@OPENSTACK.ORG

* Add the service principal's keytab to hiera.

* Create an AFS user for the service principal::

    pts createuser service.foo-mirror

Because mirrors usually have a large number of directories, it is best
to avoid frequent ACL changes.  To this end, we grant access to the
mirror directories to a group where we can easily modify group
membership if our needs change.

* Create a group to contain the service principal, and add the
  principal::

    pts creategroup foo-mirror
    pts adduser service.foo-mirror foo-mirror

  View users, groups, and their membership with::

    pts listentries
    pts listentries -group
    pts membership foo-mirror

* Grant the group access to the mirror volume::

    fs setacl /afs/.openstack.org/mirror/foo foo-mirror write

* Grant anonymous users read access::

    fs setacl /afs/.openstack.org/mirror/foo system:anyuser read

* Set the quota on the volume (e.g., 100GB)::

    fs setquota /afs/.openstack.org/mirror/foo 100000000

Because the initial replication may take more time than we allocate in
our mirror update cron jobs, manually perform the first mirror update:

* In screen, obtain the lock on mirror-update.openstack.org::

    flock -n /var/run/foo-mirror/mirror.lock bash

  Leave that running while you perform the rest of the steps.

* Also in screen on mirror-update, run the initial mirror sync.

* Log into afs01.dfw.openstack.org and run screen.  Within that
  session, periodically during the sync, and once again after it is
  complete, run::

    vos release mirror.foo -localauth

  It is important to do this from an AFS server using ``-localauth``
  rather than your own credentials and inside of screen because if
  ``vos release`` is interrupted, it will require some manual cleanup
  (data will not be corrupted, but clients will not see the new volume
  until it is successfully released).  Additionally, ``vos release`` has
  a bug where it will not use renewed tokens and so token expiration
  during a vos release may cause a similar problem.

* Once the initial sync and and ``vos release`` are complete, release
  the lock file on mirror-update.

Removing a mirror
~~~~~~~~~~~~~~~~~

If you need to remove a mirror, you can do the following:

* Check what servers volumes are on with ``vos listvldb``::

  VLDB entries for all servers

  ...

  mirror.foo
      RWrite: 536870934     ROnly: 536870935
      number of sites -> 3
         server afs01.dfw.openstack.org partition /vicepa RW Site
         server afs01.dfw.openstack.org partition /vicepa RO Site
         server afs01.ord.openstack.org partition /vicepa RO Site

   ...

* Remove the R/W replica of the volume::

    vos remove -server afs02.dfw.openstack.org -partition a -id mirror.foo

* Remove the R/O replicas (you can also see these with ``vos
  listvol -server afs0[1|2].dfw.openstack.org``)::

    vos remove -server afs01.dfw.openstack.org -partition a -id mirror.foo.readonly
    vos remove -server afs02.dfw.openstack.org -partition a -id mirror.foo.readonly

* Unmount the volume from the R/W location::

    fs rmmount /afs/.openstack.org/mirror/foo

* Release the R/O mirror volume to reflect the changes::

    vos release mirror
