:title: Stackalytics

.. _stackalytics:

Stackalytics
############

Stackalytics is a system for the analysis of OpenStack development statistics.
It is installed on stackalytics.openstack.org with a CNAME stackalytics.org
pointing to it.

At a Glance
===========

:Hosts:
  * http://stackalytics.openstack.org
:Puppet:
  * :file:`modules/stackalytics`
  * :file:`modules/openstack_project/manifests/stackalytics.pp`
:Configuration:
  * https://git.openstack.org/cgit/openstack-infra/config/tree/modules/stackalytics/tempaltes/stackalytics.conf.erb
:Projects:
  * https://git.openstack.org/cgit/stackforge/stackalytics
:Bugs:
  * http://bugs.launchpad.net/stackalytics
:Resources:
  * `How to run Stackalytics <https://wiki.openstack.org/wiki/Stackalytics/HowToRun>`_

Overview
========

Stackalytics processes the data from git, gerrit and launchpad and stores
it in memcached. A clone of each git repo is kept in /var/lib/git and is
managed by stackalytics.

There are two important programs.

The web dashboard is a WSGI app running in an Apache mod_wsgi container.

`stackalytics-processor` is a program that runs periodically to fetch data
from the development systems and populate the memcached data.
