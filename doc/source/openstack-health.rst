:title: openstack-health

.. _openstack-health:

OpenStack-Health
################

The web frontend cgit is running on git.openstack.org.

At a Glance
===========

:Hosts:
  * https://openstack-health.openstack.org
  * htstatus.openstack.org
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
running in our CI infrastructure. It is composed of 2 pieces:

#. The REST API that provides the data 
#. The JS frontend which is used to visualize the data returned by the REST
   API

The REST API is deployed on it's own server. It is written in python using flask
and is deployed using mod_wsgi under apache.

The frontend component is deployed on status.openstack.org.

Both components are continually deployed from the project repo, so as soon
as a commit lands in the openstack-health repo it will be applied to the
deployment.
