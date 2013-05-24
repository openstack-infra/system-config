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
  * :file:`modules/mediawiki`
  * :file:`modules/openstack_project/manifests/wiki.pp`
:Projects:
  * http://www.mediawiki.org/wiki/MediaWiki
:Bugs:
  * http://bugs.launchpad.net/openstack-ci

Overview
========
Much (but not all) of the configuration is in puppet in the
``openstack-infra/config`` repository.  Mediawiki upgrades are
currently performed manually.
