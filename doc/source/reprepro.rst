:title: reprepro

.. _reprepro:

Reprepro
########

Debian package mirroring tool

At a Glance
===========

:Hosts:
  * http://mirror-update.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/mirror_update.pp`
:Projects:
  * https://mirrorer.alioth.debian.org
:Documentation:
  * http://git.debian.org/?p=mirrorer/reprepro.git;a=blob_plain;hb=HEAD;f=docs/manual.html
  * https://github.com/esc/reprepro/blob/master/docs/recovery
:Bugs:
  * https://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg=reprepro;dist=unstable

Overview
========

reprepro is the tool we use to mirror Debian repositories (including
Ubuntu) to the AFS mirrors.

Repository signing
==================

Note our repositories are not signed.  ``apt`` will require
``--no-check-gpg`` or similar settings in configuration to use
OpenStack mirrors.

Normal operation
================

Repository syncs are driven from ``cron`` on the
``mirror-update.openstack.org`` host using the
``/usr/local/bin/reprepro-mirror-update`` script.  Repositories will
update, remove old references and perform the ``vos release``.

Advanced Recovery Techniques
============================

For a small repository, corruption is probably best handled by
removing the entire repository and re-syncing.  This is undesirable
for larger repositories, however.

.. note::

   Be careful with ``vos release`` which is done as part of
   ``/usr/local/bin/reprepo-mirror-update`` to avoid inadvertently
   releasing in progress work.  Also be aware the commands in that
   script by default run under ``timeout`` which you may not want in
   recovery.

Corrupt ``reprepo`` databases will halt mirroring with often obscure
symptoms.  For example, this has been seen in production with
``reprepo`` ending up hung in an silent infinite loop.  In this case,
using ``strace`` revealed the last operation was on a file-descriptor
related to a ``.db`` file, which gave a clue the databases were
corrupt.  Other failures may be possible, of course.

The following assumes you have a root shell with the correct AFS
permissions for the mirror volumes, drop into something like::

  k5start -t -f /etc/reprepro.keytab service/reprepro -- bash

In a crisis, you want to stop the cron job running to update the repo.
You can either edit it out with ``crontab -e`` and put the host in the
emergency file (so puppet doesn't replace it) or, in a pinch, take the
lock in a infinite loop like ::

  flock -n /var/run/reprepro/ubuntu.lock bash -c while true; do sleep 1000; done

Firstly check in ``dmesg`` for AFS related errors.  It is quite likely
any corruption has happened due to issues at this layer, so ensure
stability here before continuing to further recovery.

We will use the Ubuntu repository as an example below.

The databases are in the ``db`` directory::

  # ls /afs/.openstack.org/mirror/ubuntu/db
  checksums.db  contents.cache.db  packages.db  references.db  release.caches.db  version

It is best to make backup copies before any recovery operations.  From
the upstream recovery document, the ``references.db`` can be removed
and recreated quickly with::

  reprepro -VVV --confdir /etc/reprepro/ubuntu rereference

The ``checksums.db`` can also be recreated.  You can rebuild with::

  cd /afs/.openstack.org/mirror/ubuntu
  find -type f -printf "pool/%P\n" > /tmp/file-list
  reprepro -VVV --confdir /etc/reprepro/ubuntu -b . _detect < /tmp/file-list

* Although AFS /should/ keep up, it may be prudent to do this on a
  local copy of the ``db`` directory to avoid any intermittent issues
  there further corrupting the database, then copy back the updated
  files when complete.
* This will take several hours (~6 hours in 2017) as it touches all
  the repo files.

Note that if the ``.deb`` files on disk are corrupt, this may lead to
errors on update about mismatching checksums which have been stored in
the database.  Likely you want to remove these files from disk and
from the checksums database with a command similar to::

   reprepro --confdir /etc/reprepro/ubuntu -VVVV _forget pool/main/p/package/the_package_1.2.3.deb
   rm pool/main/p/package/the_package_1.2.3.deb

They should come back with the next update.

In some situations where things are very out of sync, it may be easier
to remove and replace an entire section of the repository.  For
example, if during updates files within ``xenial-security`` are seen
to be corrupt, you can remove ``xenial-security`` from
``/etc/reprepro/ubuntu/distributions`` and run the following::

  # remove old
  reprepro -VVV --confdir /etc/reprepro/ubuntu --delete clearvanished
  # run an update
  reprepro -VVV --confdir /etc/reprepro/ubuntu update

You can then re-add the entries and run another update, which should
resync everything from fresh.

To stage a recovery prior to release, you can modify the
``mirror_root`` argument in ``openstack_project::mirror`` puppet to
point to the RW mirror ``/afs/.openstack.org/mirror`` (rather than the
released RO ``/afs/openstack.org/mirror``).  This way you can switch
back quickly if things don't work.
