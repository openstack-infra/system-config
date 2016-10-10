:title: openstack-health

.. _openstack-health:

OpenStack-Health
################

At a Glance
===========

:Hosts:
  * API Server: http://health.openstack.org
  * Frontend: http://status.openstack.org/openstack-health
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-openstack_health/tree/
  * :file:`modules/openstack_project/manifests/openstack_health_api.pp`
  * :file:`modules/openstack_project/manifests/status.pp`
:Configuration:
  * :file:`modules/openstack_project/files/git/cgitrc`
:Projects:
  * https://git.openstack.org/cgit/openstack/openstack-health/tree

Overview
========

The OpenStack Health dashboard provides a view of the status of all the tests
running in our continuous integration infrastructure that we collect results
data in subunit2sql for. It is composed of 2 pieces:

#. The REST API that provides the data used for the dashboard visualizations
#. The JS frontend which is used to visualize the data returned by the REST
   API

The REST API is deployed on it's own server. It is written in python using flask
and is deployed using mod_wsgi under apache.

The frontend component is deployed on status.openstack.org.

Both components are continually deployed from the project repo, so as soon
as a commit lands in the openstack-health repo it will be applied to the
deployment.
