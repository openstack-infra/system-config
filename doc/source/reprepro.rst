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

``reprepro`` is the tool we use to mirror Debian repositories
(including Ubuntu) to the AFS mirrors.

When updating package mirrors, it is undesirable for the index to be
out of sync with the actual packages on disk, and vice-versa.  This is
generally achieved by syncing in two stages -- firstly obtaining new
files in the mirror and then secondly updating the indexes (and
removing no-longer referenced files).

Problems occur if the upstream mirror updates itself during this
process (which may happen up to 4 times a day).  Debian, for example
runs a "push" model where first-tier mirrors are notified of
in-progress updates (see
`<https://salsa.debian.org/mirror-team/archvsync/>`__) and can restart
any in-progress syncs to maintain consistency.  OpenStack Infra is not
suitable to apply for these notifications, as our mirror is not
intended to be public and may be incomplete (we may not mirror all
suites, or architectures, etc. as our needs dictate).  This means if
using other tools like `ftpsync
<https://salsa.debian.org/mirror-team/archvsync>`__ primarily intended
for full replication we are very likely to have periods where our
mirror gets out of sync (with subsequent job failures).

``reprepro`` is more commonly used to build and manage private
repositories, but has a number of features making it suitable for our
use.

Rather than sync upstream indexes, it recreates them based upon files
gathered from the upstream mirror.  Since the upstream mirror remains
consistent, ``reprepro`` will always download a consistent set of
files.  Then thanks to the release of the AFS mirror volume being
atomic, we do not have any period where the repository package index
doens't match the set of packages in the filesystem.

Since this does not require coordination with upstream, the same
pattern is suitable across Ubuntu, Debian and other various apt
repositories that may require integration (or perhaps do not provide
facilities) for correct mirroring.  Although ``reprepro`` can be more
complicated to configure, it is consistent across these different
distributions.

``reprepro`` also makes it fairly easy to mirror only certain suites
or architectures for a given repository, and to modify these
configurations as required.

Repository signing
==================

Note our repositories are not signed since ``reprepro`` recreates the
indexes from scratch.  This is actually somewhat helpful in avoiding
the infra mirrors becoming de facto mirrors for a range of unrelated
jobs (since we really do not guarantee contents for anything other
than infra jobs).

``apt`` will require ``--no-check-gpg`` or similar settings in
configuration to use OpenStack mirrors.

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

We will use the Ubuntu repository as an example below.

In a crisis, you want to stop the cron job running to update the repo.
You can either edit it out with ``crontab -e`` and put the host in the
emergency file (so puppet doesn't replace it) or, in a pinch, take the
lock in a infinite loop like ::

  flock -n /var/run/reprepro/ubuntu.lock bash -c while true; do sleep 1000; done

Firstly check in ``dmesg`` for AFS related errors.  It is quite likely
any corruption has happened due to issues at this layer, so ensure
stability here before continuing to further recovery.

The databases are in the ``db`` directory in the mirror::

  # ls /afs/.openstack.org/mirror/ubuntu/db
  checksums.db  contents.cache.db  packages.db  references.db  release.caches.db  version

It is best to make backup copies before any recovery operations.
Although AFS /should/ keep up, you should do any recovery of the
``db`` directory on a local copy to avoid any intermittent issues
there further corrupting the database, then copy back the updated
files when complete.::

  # cp -r /afs/.openstack.org/mirror/ubuntu/db ~/db

For convenience, setup the common ``reprepo`` options for verbose
logging, the configuration directory and to work on the local
database::

  # export REPREPRO="reprepro -VVV --confdir /etc/reprepro/ubuntu --dbdir ~/db"

From the upstream recovery document, the ``references.db`` can be
removed and recreated quickly with::

  $REPREPRO rereference

The ``checksums.db`` can also be recreated.  You can rebuild with::

  cd /afs/.openstack.org/mirror/ubuntu
  find -type f -printf "pool/%P\n" > /tmp/file-list
  $REPREPRO -b . _detect < /tmp/file-list

* This will take several hours (~6 hours in 2017) as it touches all
  the repo files.

Note that if the ``.deb`` files on disk are corrupt, this may lead to
errors on update about mismatching checksums which have been stored in
the database.  Likely you want to remove these files from disk and
from the checksums database with a command similar to::

   $REPREPRO _forget pool/main/p/package/the_package_1.2.3.deb
   rm pool/main/p/package/the_package_1.2.3.deb

They should come back with the next update.

In some situations where things are very out of sync, it may be easier
to remove and replace an entire section of the repository.  For
example, if during updates files within ``xenial-security`` are seen
to be corrupt, you can remove ``xenial-security`` from
``/etc/reprepro/ubuntu/distributions`` and run the following::

  # remove old
  $REPREPRO --delete clearvanished
  # run an update
  $REPREPRO update

You can then re-add the entries and run another update, which should
resync everything from fresh.

You may also see errors relating to individual packages not being
referenced correctly::

  checking references to 'bionic|main|arm64' for 'texlive-latex-base': pool/main/t/texlive-base/texlive-latex-base_2017.20180305-1_all.deb
  Missing reference to 'pool/main/t/texlive-base/texlive-latex-base_2017.20180305-1_all.deb' by 'bionic|main|arm64'
  ...
  There have been errors!

In this case, the ``_addreference`` command can be useful.  The
parameters are the *filekey*, which is the path to the file, and the
*identifier*, which is the tuple ``bionic|main|arm64`` above.  To
restore the reference try::

  # $REPREPRO _addreference pool/main/t/texlive-base/texlive-latex-base_2017.20180305-1_all.deb 'bionic|main|arm64'
  Adding reference to 'pool/main/t/texlive-base/texlive-latex-base_2017.20180305-1_all.deb' by 'bionic|main|arm64'

Remember to put the databases back in place::

  # mv /afs/.openstack.org/mirror/ubuntu/db /afs/.openstack.org/mirror/ubuntu/db.old
  # cp -r ~/db  /afs/.openstack.org/mirror/ubuntu/

To stage a recovery prior to release, you can modify the
``mirror_root`` argument in ``openstack_project::mirror`` puppet to
point Apache to the RW mirror ``/afs/.openstack.org/mirror`` where
fixes are deployed, rather than the released RO
``/afs/openstack.org/mirror``.  This way you can avoid having to
release the RO mirror and switch back quickly if things don't work.

When fixed, you can either manually run ``vos release``, or restore
cron and let the next ``reprepro-mirror-update`` run do it.
