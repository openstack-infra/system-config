:title: Nodepool

.. _nodepool:

Nodepool
########

Nodepool is a service used by the OpenContrail CI team to deploy and manage a pool
of devstack images on a cloud server for use in OpenContrail project testing.

At a Glance
===========

:Hosts:
  * nodepool.opencontrail.org
:Puppet:
  * :file:`modules/nodepool/`
  * :file:`modules/opencontrail_project/manifests/single_use_slave.pp`
:Configuration:
  * :file:`modules/opencontrail_project/templates/nodepool/nodepool.yaml.erb`
  * :file:`modules/opencontrail_project/files/nodepool/scripts/`
:Projects:
  * https://git.opencontrail.org/opencontrail-infra/nodepool
:Bugs:
  * http://bugs.launchpad.net/opencontrail-ci

Overview
========

Once per day, for every image type (and provider) configured by nodepool, a new
image with cached data for use by devstack.  Nodepool spins up new instances
and tears down old as tests are queued up and completed, always maintaining a
consistant number of available instances for tests up to the set limits of the
CI infrastructure.
