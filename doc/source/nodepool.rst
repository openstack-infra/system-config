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
  * https://git.openstack.org/cgit/openstack-infra/puppet-openstackci/tree/manifests/nodepool.pp
  * :file:`modules/openstack_project/manifests/single_use_slave.pp`
:Configuration:
  * :config:`nodepool/nodepool.yaml`
  * :config:`nodepool/scripts/`
  * :config:`nodepool/elements/`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/nodepool
:Bugs:
  * https://storyboard.openstack.org/#!/project/668
:Resources:
  * `Nodepool Reference Manual <http://docs.openstack.org/infra/nodepool>`_
  * `ZooKeeper Programmer's Guide <https://zookeeper.apache.org/doc/trunk/zookeeperProgrammers.html>`_
  * `ZooKeeper Administrator's Guide <https://zookeeper.apache.org/doc/trunk/zookeeperAdmin.html>`_
  * `zk_shell <https://pypi.python.org/pypi/zk_shell/>`_

Overview
========

Once per day, for every image type (and provider) configured by
nodepool, a new image with cached data is built for use by devstack.
Nodepool spins up new instances and tears down old as tests are queued
up and completed, always maintaining a consistent number of available
instances for tests up to the set limits of the CI infrastructure.

Zookeeper
=========

Nodepool stores image metadata in ZooKeeper.  We have a one-node
ZooKeeper "cluster" running on nodepool.openstack.org.

The Nodepool CLI should be sufficient to examine and alter any of the
information stored in ZooKeeper.  However, in case advanced debugging
is needed, use of zk-shell ("pip install zk_shell" into a virtualenv
and run "zk-shell") is recommended as an easy way to inspect and/or
change data in ZooKeeper.

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
``ubuntu-precise`` image is problematic, you can run::

  $ sudo nodepool dib-image-list

  +---------------------------+----------------+---------+-----------+----------+-------------+
  | ID                        | Image          | Builder | Formats   | State    | Age         |
  +---------------------------+----------------+---------+-----------+----------+-------------+
  | ubuntu-precise-0000000001 | ubuntu-precise | nb01    | qcow2,vhd | ready    | 02:00:57:33 |
  | ubuntu-precise-0000000002 | ubuntu-precise | nb01    | qcow2,vhd | ready    | 01:00:57:33 |
  +---------------------------+----------------+---------+-----------+----------+-------------+

Image ubuntu-precise-0000000001 is the previous image and
ubuntu-precise-0000000002 is the current image (they are both marked
as ``ready`` and the current image is simply the image with the
shortest age.

Nodepool aggressively attempts to build and upload missing images, so
if the problem with the image will not be solved with an immediate
rebuild, image builds must first be disabled for that image.  To do
so, add ``paused: True`` to the ``diskimage`` section for
``ubuntu-precise`` in nodepool.yaml.

Then delete the problematic image with::

  $ sudo nodepool dib-image-delete ubuntu-precise-0000000002

All uploads corresponding to that image build will be deleted from providers
before the image DIB files are deleted. The previous image will become the
current image and nodepool will use it when creating new nodes. When nodepool
next creates an image, it will still retain build #1 since it will still be
considered the next-most-recent image.

vhd-util
========

Creating images for Rackspace requires a patched version of vhd-util to convert
the images into the appropriate VHD format. A package is manaually managed
at `ppa:openstack-ci-core/vhd-util` and is based on a git repo at
https://github.com/emonty/vhd-util

Updating vhd-util
-----------------

Should it become required to update vhd-util before Infra has a proper
packaging repo or solution in place, one should clone from the git repo::

  $ git clone git://github.com/emonty/vhd-util
  $ cd vhd-util

Then perform whatever updates and packaging work are needed. The repo is
formatted as a git-buildpackage repo with `--pristine-tar`. When you're ready
to upload a new verion, commit, create a source package and a tag::

  $ git-buildpackage --git-tag --git-sign-tags -S

This will make a source package in the parent directory. Upload it to
launchpad::

  $ cd ..
  $ dput ppa:openstack-ci-core/vhd-util vhd-util_$version_source.changes

Then probably pushing the repo to github and submitting a pull request so that
we can keep up with the change is not a terrible idea.
