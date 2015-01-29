:title: Planet

.. _planet:

Planet
######

The `Planet Venus
<http://intertwingly.net/code/venus/docs/index.html>`_ blog aggregator
is installed on planet.openstack.org.

At a Glance
===========

:Hosts:
  * http://planet.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-planet/tree/
  * :file:`modules/openstack_project/manifests/planet.pp`
:Configuration:
  * https://git.openstack.org/cgit/openstack/openstack-planet/tree/planet.ini
:Projects:
  * https://git.openstack.org/cgit/openstack/openstack-planet
  * http://www.intertwingly.net/code/venus/
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
:Resources:
  * `Planet Venus Documentation <http://intertwingly.net/code/venus/docs/index.html>`_

Overview
========

Planet Venus works by having a cron job which creates static files.
In our configuration, the static files are served using Apache.

The puppet module is configured to use the openstack/planet git
repository to provide the ``planet.ini`` configuration file.
