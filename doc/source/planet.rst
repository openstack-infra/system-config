:title: Planet

.. _planet:

Planet
######

The `Planet Venus
<http://intertwingly.net/code/venus/docs/index.html>`_ blog aggregator
is installed on planet.opencontrail.org.

At a Glance
===========

:Hosts:
  * http://planet.opencontrail.org
:Puppet:
  * :file:`modules/planet`
  * :file:`modules/opencontrail_project/manifests/planet.pp`
:Configuration:
  * https://git.opencontrail.org/cgit/opencontrail/opencontrail-planet/tree/planet.ini
:Projects:
  * https://git.opencontrail.org/cgit/opencontrail/opencontrail-planet
  * http://www.intertwingly.net/code/venus/
:Bugs:
  * http://bugs.launchpad.net/opencontrail-ci
:Resources:
  * `Planet Venus Documentation <http://intertwingly.net/code/venus/docs/index.html>`_

Overview
========

Planet Venus works by having a cron job which creates static files.
In our configuration, the static files are served using Apache.

The puppet module is configured to use the opencontrail/planet git
repository to provide the ``planet.ini`` configuration file.
