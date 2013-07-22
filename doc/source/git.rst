:title: Git

.. _git:

Git
########

The web frontend cgit is running on git.openstack.org.

At a Glance
===========

:Hosts:
  * https://git.openstack.org
:Puppet:
  * :file:`modules/cgit`
  * :file:`modules/openstack_project/manifests/git.pp`
:Projects:
  * http://git.zx2c4.com/cgit/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * http://lists.zx2c4.com/mailman/listinfo/cgit

Overview
========

Apache is running on a CentOS 6 system with the EPEL repository that includes
the cgit packages.
