:title: Wiki

.. _wiki:

Wiki
####

`Mediawiki <http://www.mediawiki.org/wiki/MediaWiki>`_ is installed on
wiki.openstack.org.

At a Glance
===========

:Hosts:
  * https://wiki.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-mediawiki/tree/
  * :file:`modules/openstack_project/manifests/wiki.pp`
:Projects:
  * http://www.mediawiki.org/wiki/MediaWiki
:Bugs:
  * https://storyboard.openstack.org/#!/project/748

Overview
========
wiki.openstack.org runs off of Wikmedia Foundation deployment branches.
This was done to ease the pain of managing Mediawiki extensions. The
foundation branches come with git submodules that refer to known good
versions of extensions. Much (but not all) of the configuration is in
puppet in the ``openstack-infra/system-config`` repository.  Mediawiki
upgrades are currently performed manually.

Mediawiki Upgrades
==================

Two versions of Mediawiki are installed with one being the active
install and the other being previously used version kept as a backup.
The two installs can be found at ``/srv/mediawiki/slot0`` and
``/srv/mediawiki/slot1``. The ``/srv/mediawiki/w`` symlink refers to
active Mediawiki install slot. To perform a Mediawiki upgrade:

  #. Determine which install slot is active ``ls -l /srv/mediawiki/w``.
     Once this value is known do not use ``/srv/mediawiki/w`` in your
     commands, doing so will break the git submodules. Always use
     specific slot paths eg ``/srv/mediawiki/slot0``.
  #. Fetch the latest git content in the inactive slot
     ``cd /srv/mediawiki/$INACTIVE_SLOT && git fetch``.
  #. Find the latest Wikimedia Foundation branch ``git branch -a``.
     Make sure this version matches
     http://www.mediawiki.org/wiki/Special:Version we don't want to
     upgrade until that upstream is running the latest version.
  #. Create and checkout a local tracking branch for the latest upstream
     branch ``git checkout -b wmf/1.22wmf11 origin/wmf/1.22wmf11``.
  #. Update the git submodules for this new branch
     ``git submodule update --init``.
  #. Take stock of the current state of extensions ``git status``.
     You should see several untracked dirs for things like the strapping
     skin and openid. Any untracked extensions that we are not using
     should be removed.
  #. Update the untracked extensions that we are using
     ``cd $EXTENSION_DIR && git pull origin master``. Note there may be
     conflicts doing this if security patches or bug fixes have been
     applied by hand. Refer to /srv/mediawiki/NOTES for info.
  #. Run the backup script ``/srv/mediawiki/backup.sh``. This will backup
     the active slot to ``/srv/backup``.
  #. Update the DB schemas ``php maintenance/update.php --quick``. Be
     sure to run this within the slot you are upgrading (the inactive
     slot). If you used the ``cd`` in step 2 this should be the case.
     Mediawiki DB schemas are backward compatible so we can upgrade it
     without taking down the active slot.
  #. If there were updates to the CirrusSearch extension, search may stop
     working unless the index is rebuilt. The easiest way to do this is
     ``php extensions/CirrusSearch/maintenance/updateSearchIndexConfig.php
     --startOver`` followed by ``php
     extensions/CirrusSearch/maintenance/forceSearchIndex.php`` relative to
     the inactive slot you've upgraded (option 1.A as described at
     https://git.wikimedia.org/blob/mediawiki%2Fextensions%2FCirrusSearch.git/HEAD/README
     in the upgrading section).
  #. At this point we are ready to change the ``/srv/mediawiki/w``
     symlink to point to the slot we just upgraded
     ``rm -f /srv/mediawiki/w && ln -s /srv/mediawiki/$PREVIOUSLY_INACTIVE_SLOT /srv/mediawiki/w``.
     https://wiki.openstack.org/wiki/Special:Version should report the
     new version now.
