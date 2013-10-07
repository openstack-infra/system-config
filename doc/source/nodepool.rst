:title: Nodepool

.. _nodepool:

Nodepool
########

Nodepool is a service used by the OpenStack CI team to deploy and manage a pool
of devstack images on a cloud server for use in OpenStack project testing.

At a Glance
===========

:Hosts:
  * nodepool.openstack.org
:Puppet:
  * :file:`modules/nodepool/`
  * :file:`modules/openstack_project/manifests/dev_slave_template.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/nodepool/nodepool.yaml.erb`
  * :file:`modules/openstack_project/files/nodepool/scripts/`
:Projects:
  * https://git.openstack.org/openstack-infra/nodepool
:Bugs:
  * http://bugs.launchpad.net/openstack-ci

Overview
========

Once per day, for every image type (and provider) configured by nodepool, a new
image with cached data for use by devstack.  Nodepool spins up new instances
and tears down old as tests are queued up and completed, always maintaining a
consistant number of available instances for tests up to the set limits of the
CI infrastructure.
