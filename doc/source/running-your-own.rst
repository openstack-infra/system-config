:title: Running your own CI infrastructure

.. _running-your-own:

Running your own CI infrastructure
##################################

The OpenStack CI infrastructure is designed to be shared amongst other projects
wanting a scalable cloud based CI system. We're delighted when someone wants to
reuse what we're building.

To avoid having lots of meta references in the rest of the system
documentation, we document most things targeted specifically for use in the
OpenStack CI system itself. This chapter acts as a patch to the rest of our
documentation explaining how to reuse the OpenStack CI infrastructure for
another project.

Requirements
============

* You need a cloud of some sort, all our tooling is built for OpenStack clouds :).

* A service account for your CI systems within that cloud/clouds.

* A domain for your servers to live in; puppet is hostname based, having
  everything in sync is just easier.

* A git repository that you can store your code in :).

Initial setup
=============

1. Clone the CI config repository and adjust it as necessary.

1. Manually boot a machine with ~2G of ram to be the puppetmaster.

1. Follow http://ci.openstack.org/puppet.html#id2 but use your repository
   rather than the OpenStack CI repository.

