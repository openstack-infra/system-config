HOWTO: Add a Project to StackForge
==================================

Overview
--------

StackForge is a Gerrit review and Jenkins CI setup similar to that of the main
OpenStack project but for use with projects that are not under the main
OpenStack umbrella.

Any project can be added to StackForge as long as it is related to OpenStack in
some way.

Launchpad
---------

All the developers of the project need to sign up to Launchpad and a team is
needed for the core project reviewers to join.  This team also needs to be
a sub-team of the `OpenStack team <https://launchpad.net/~openstack>`_ so that
Gerrit will be able to see it.

GitHub
------

If you already have a branch on GitHub for the project this will need moving to
the StackForge GitHub organization.  Otherwise a new branch will need creating
for you.  The OpenStack Core Infrastructure team can assist in this.

Jenkins and Gerrit
------------------

Until the setup is more automated the OpenStack Core Infrastructure team will
need to do the Jenkins and Gerrit portion of the setup too.  If you project is
Python based we have a `Project Testing Interface <http://wiki.openstack.org/ProjectTestingInterface>`_ that we prefer you use.  Otherwise please let the CI
team know the testing requirements for Jenkins.

Contacting the CI Team
----------------------

The best way to get the CI team to help with the above steps is to `file a CI bug <https://bugs.launchpad.net/openstack-ci>`_.  We are also available on the
#openstack-infra IRC channel or to the `CI Admins email address <mailto:openstack-ci-admins@lists.launchpad.net>`_.
