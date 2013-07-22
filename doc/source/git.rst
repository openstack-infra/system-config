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
:Configuration:
  * :file:`modules/openstack_project/files/git/cgitrc`
:Projects:
  * http://git.zx2c4.com/cgit/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * http://lists.zx2c4.com/mailman/listinfo/cgit

Overview
========

The OpenStack git repositories are hosted on this server and served up via
https using cgit and via git:// by git-daemon.

Apache is running on a CentOS 6 system with the EPEL repository that includes
the cgit package. SELinux is enabled and requires restorecon to be run against
/var/lib/git to set the appropriate SELinux security context, this is handled
by puppet.

The jeepyb script create-cgitrepos runs against projects.yaml to generate the
/etc/cgitrepos file listing all the git repositories. The git repositories are
synced from the Gerrit server.
