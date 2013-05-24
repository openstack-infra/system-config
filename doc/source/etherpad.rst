:title: Etherpad

.. _etherpad:

Etherpad
########

Etherpad (previously known as "etherpad-lite") is installed on
etherpad.openstack.org to facilitate real-time collaboration on
documents.  It is used extensively during OpenStack Developer
Summits.

At a Glance
===========

:Hosts:
  * http://etherpad.openstack.org
:Puppet:
  * :file:`modules/etherpad_lite`
  * :file:`modules/openstack_project/manifests/etherpad.pp`
  * :file:`modules/openstack_project/manifests/etherpad_dev.pp`
:Projects:
  * http://etherpad.org/
  * https://github.com/ether/etherpad-lite
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * https://github.com/ether/etherpad-lite/issues

Overview
========

Apache is configured as a reverse proxy and there is a MySQL database
backend.
