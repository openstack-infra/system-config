:title: Security Gerrit

.. _gerrit:

Security Gerrit
###############

Security Gerrit is a private Gerrit instance we use for reviewing
security patches.  We setup this instance so that we can provide
a set of trusted users access to security patches.

This section describes how security Gerrit is configured.  To understand
security Gerrit you will need to familiarized yourself with the setup
and configuration of our open Gerrit.  This is a subset of the information
found in :doc:`open Gerrit documentation <gerrit>`

At a Glance
===========

:Hosts:
  * http://review-security.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/review_security.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/review.projects.yaml.erb`
:Projects:
  * http://code.google.com/p/gerrit/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * http://code.google.com/p/gerrit/issues/list
:Resources:
  * `Gerrit Documentation <https://review.openstack.org/Documentation/index.html>`_

.. _acl:

Access Controls
===============

High level goals:

#. Security users can read all projects.
#. All Security users can perform informational code review (+/-1)
   on any project.
#. Jenkins can perform verification (blocking or approving: +/-1).
#. All Security users can create changes.
#. Members of Vulnerability Managers group can perform full code review
   (blocking or approving: +/- 2), and submit changes to be merged.
#. The Vulnerability Managers and Jenkins can tag releases (push
   annotated tags).

The `project.config` should look like::

  [project]
      description = Rights inherited by all other projects
      state = active
  [access "refs/*"]
      read = group Anonymous Users
      pushTag = group Continuous Integration Tools
      pushTag = group Project Bootstrappers
      pushTag = group Release Managers
      forgeAuthor = group Registered Users
      forgeCommitter = group Project Bootstrappers
      push = +force group Project Bootstrappers
      create = group Project Bootstrappers
      create = group Release Managers
      pushMerge = group Project Bootstrappers
  [access "refs/heads/*"]
      label-Code-Review = -2..+2 group Project Bootstrappers
      label-Code-Review = -1..+1 group Registered Users
      label-Verified = -2..+2 group Continuous Integration Tools
      label-Verified = -2..+2 group Project Bootstrappers
      label-Verified = -1..+1 group External Testing Tools
      submit = group Continuous Integration Tools
      submit = group Project Bootstrappers
      label-Approved = +0..+1 group Project Bootstrappers
  [access "refs/meta/config"]
      read = group Project Owners
  [access "refs/for/refs/*"]
      push = group Registered Users
  [access "refs/heads/milestone-proposed"]
      exclusiveGroupPermissions = label-Approved label-Code-Review
      label-Code-Review = -2..+2 group Project Bootstrappers
      label-Code-Review = -2..+2 group Release Managers
      label-Code-Review = -1..+1 group Registered Users
      owner = group Release Managers
      label-Approved = +0..+1 group Project Bootstrappers
      label-Approved = +0..+1 group Release Managers
  [access "refs/heads/stable/*"]
      forgeAuthor = group Stable Maintainers
      forgeCommitter = group Stable Maintainers
      exclusiveGroupPermissions = label-Approved label-Code-Review
      label-Code-Review = -2..+2 group Project Bootstrappers
      label-Code-Review = -2..+2 group Stable Maintainers
      label-Code-Review = -1..+1 group Registered Users
      label-Approved = +0..+1 group Project Bootstrappers
      label-Approved = +0..+1 group Stable Maintainers
  [access "refs/meta/openstack/*"]
      read = group Continuous Integration Tools
      create = group Continuous Integration Tools
      push = group Continuous Integration Tools
  [capability]
      administrateServer = group Administrators
      priority = batch group Non-Interactive Users
      createProject = group Project Bootstrappers
  [access "refs/zuul/*"]
      create = group Continuous Integration Tools
      push = +force group Continuous Integration Tools
      pushMerge = group Continuous Integration Tools
  [access "refs/for/refs/zuul/*"]
      pushMerge = group Continuous Integration Tools
