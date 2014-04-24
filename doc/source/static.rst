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

See :ref:`cinder` for details on volume management.
