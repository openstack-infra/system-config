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
  * https://git.openstack.org/cgit/openstack-infra/puppet-nodepool/tree/
  * :file:`modules/openstack_project/manifests/nodepool_prod.pp`
  * :file:`modules/openstack_project/manifests/single_use_slave.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/nodepool/nodepool.yaml.erb`
  * :config:`nodepool/scripts/`
  * :config:`nodepool/elements/`
:Projects:
  * https://git.openstack.org/openstack-infra/nodepool
:Bugs:
  * https://storyboard.openstack.org/#!/project/668
:Resources:
  * `Nodepool Reference Manual <http://ci.openstack.org/nodepool>`_

Overview
========

Once per day, for every image type (and provider) configured by nodepool, a new
image with cached data for use by devstack.  Nodepool spins up new instances
and tears down old as tests are queued up and completed, always maintaining a
consistent number of available instances for tests up to the set limits of the
CI infrastructure.

Bad Images
==========

Since nodepool takes a while to build images, and generally only does
it once per day, occasionally the images it produces may have
significant behavior changes from the previous versions.  For
instance, a provider's base image or operating system package may
update, or some of the scripts or system configuration that we apply
to the images may change.  If this occurs, it is easy to revert to the
last good image.

Nodepool periodically deletes old images, however, it never deletes
the current or next most recent image in the ``ready`` state for any
image-provider combination.  So if you find that the
``devstack-precise`` images for a single or all providers are
problematic, you can run::

  $ sudo nodepool image-list

  +--------+--------------------+------------------------+----------------------------------------------------------+------------+--------------------------------------+--------------------------------------+----------+-------------+
  | ID     | Provider           | Image                  | Hostname                                                 | Version    | Image ID                             | Server ID                            | State    | Age (hours) |
  +--------+--------------------+------------------------+----------------------------------------------------------+------------+--------------------------------------+--------------------------------------+----------+-------------+
  | 168655 | hpcloud-az2        | devstack-precise       | devstack-precise-1394417686.template.openstack.org       | 1394417686 | 387612                               | 4909797                              | ready    | 26.83       |
  | 168696 | hpcloud-az2        | devstack-precise       | devstack-precise-1394514268.template.openstack.org       | 1394514268 | 388782                               | 4930213                              | ready    | 0.75        |
  +--------+--------------------+------------------------+----------------------------------------------------------+------------+--------------------------------------+--------------------------------------+----------+-------------+

Image 168655 is the previous image and 168696 is the current image
(they are both marked as ``ready`` and the current image is simply the
image with the shortest age.  Delete the problematic image with::

  $ sudo nodepool delete-image 168696

Then the previous image, 168655, will become the current image and
nodepool will use it when creating new nodes.  When nodepool next
creates an image, it will still retain 168655 since it will still be
considered the next-most-recent image.
