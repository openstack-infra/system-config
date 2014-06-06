:title: Elastic-Recheck

.. _elastic-recheck:

Elastic-Recheck
######



At a Glance
===========

:Hosts:
  * http://status.openstack.org
:Puppet:
  * :file:`modules/elastic_recheck`
  * :file:`modules/openstack_project/manifests/status.pp`
:Projects:
 * https://git.openstack.org/cgit/openstack-infra/elastic-recheck
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
:Resources:
  * `elastic-recheck Documentation <http://docs.openstack.org/infra/elastic-recheck/>`_

Overview
========

The elastic-recheck project leverages Elasticsearch and Logstash to identify,
track and report upon rechecks in the OpenStack gate.

Dashboard can be found here:

http://status.openstack.org/elastic-recheck/
