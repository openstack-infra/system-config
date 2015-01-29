:title: Bandersnatch

.. _bandersnatch:

Bandersnatch
############

A pypi mirror tool

At a Glance
===========

:Hosts:
  * http://pypi.openstack.org (deprecated)
  * http://pypi.iad.openstack.org
  * http://pypi.dfw.openstack.org
  * http://pypi.ord.openstack.org
  * http://pypi.region-b.geo-1.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/static.pp`
:Projects:
  * https://pypi.python.org/pypi/bandersnatch
:Documentation:
  * https://pypi.python.org/pypi/bandersnatch#configuration
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * https://bitbucket.org/pypa/bandersnatch/issues?status=new&status=open

Overview
========

Bandersnatch is a tool we run on the static.openstack.org host to
build a complete mirror of pypi.python.org. Cron execs bandersnatch
on an interval with logs going to ``/var/log/bandersnatch``.

Stale Packages
==============

There is an issue with pypi.python.org syncing to its CDN occasionally
resulting in stale package artifacts. You will notice this in the
bandersnatch logs as::

  2014-07-11 01:30:04,592 INFO: Syncing package: python-novaclient (serial 1154164)
  2014-07-11 01:30:04,592 DEBUG: Getting /pypi/python-novaclient/json (serial 1154164)
  2014-07-11 01:30:04,599 DEBUG: Expected PyPI serial 1154164 for request https://pypi.python.org/pypi/python-novaclient/json but got 1154163
  2014-07-11 01:30:04,599 ERROR: Stale serial for package python-novaclient
  2014-07-11 01:30:04,599 ERROR: Stale serial for python-novaclient (1154164) not updating. Giving up.

The fix for this is to issue a PURGE against the url specified above::

  curl -X PURGE https://pypi.python.org/pypi/python-novaclient/json

The next run of bandersnatch will sync the package. Note this PURGE
step should be performed automatically by our bandersnatch wrapper
script, but can be performed by hand safely if necessary.
