:title: Apps Site

.. _apps_site:

Apps Site
#########

The `OpenStack Community App Catalog
<http://apps.openstack.org>`_ is installed on
apps.openstack.org.

At a Glance
===========

:Hosts:
  * http://apps.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-apps_site/tree/
:Projects:
  * https://github.com/stackforge/apps-catalog
:Bugs:
  * https://storyboard.openstack.org/#!/project/817
:Resources:
  * `App Catalog Documentation <https://wiki.openstack.org/wiki/App-Catalog>`_

Overview
========

The OpenStack Community App Catalog works by having contributors
submit patches to modify YAML files in the repository
https://github.com/stackforge/apps-catalog. The puppet module
when executed pulls an updates to that repository which are
then served at http://apps.openstack.org.

More information on the App Catalog can be found at
https://wiki.openstack.org/wiki/App-Catalog
