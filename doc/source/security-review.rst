:title: Security Gerrit

.. _gerrit:

Security Gerrit
###############

Security Gerrit is a private Gerrit instance we use for reviewing
security patches.  We setup this instance so that we can provide
a set of trusted users access to security patches.

This section describes how security Gerrit is configured.  To understand
security Gerrit you will need to familiarize yourself with the setup
and configuration of our open Gerrit.  This is a subset of the information
found in :doc:`open Gerrit documentation <gerrit>`

At a Glance
===========

:Hosts:
  * http://security-review.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/security_review.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/security-review.projects.yaml.erb`
:Projects:
  * http://code.google.com/p/gerrit/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * http://code.google.com/p/gerrit/issues/list
:Resources:
  * `Gerrit Documentation <https://review.openstack.org/Documentation/index.html>`_

.. _acl:

Workflow
========
The security review instance of gerrit will have a slightly different workflow
than `the open Gerrit <https://wiki.openstack.org/wiki/GerritJenkinsGit>`_.

The security review workflow:

#. User clones a project from security-review.o.o
#. User adds a git remote to security-review.o.o
#. User executes git review patch to security-review.o.o
#. The patch is review-able by member of VMT group, change owner and
   any manually added reviewer.
#. The patch is reviewed and approved on security-review.o.o
#. The patch is copied from security-review.o.o to public review.o.o
     a. git review -d patch from security-review.o.o
     b. git review -r patch to review.o.o [1]_

.. [1] patch set information (votes/comments/etc..) does not not get
   copied to review.o.o

Access Controls
===============

High level goals:

#. Security Users can read all projects.
#. Security Users can create changes.
#. Security Users can perform informational code review (+/-1)
   on any project.
#. Vulnerability Managers can perform full code review.
   (blocking or approving: +/- 2), and submit changes to be merged.
#. Vulnerability Managers can add and remove users from Security Users group.

The `All-Projects.config` should look like::

  [access "refs/*"]
  create = group Project Bootstrappers
  create = group Release Managers
  create = group Vulnerability Managers
  forgeAuthor = group Registered Users
  forgeCommitter = group Project Bootstrappers
  push = +force group Project Bootstrappers
  pushMerge = group Project Bootstrappers
  pushSignedTag = group Project Bootstrappers
  pushTag = group Project Bootstrappers
  pushTag = group Release Managers
  read = group Anonymous Users

  [access "refs/drafts/*"]
  push = block group Registered Users

  [access "refs/for/refs/*"]
  push = group Registered Users

  [access "refs/heads/*"]
  label-Code-Review = -1..+1 group Registered Users
  label-Verified = -2..+2 group Project Bootstrappers
  label-Workflow = -1..+0 group Change Owner
  submit = group Project Bootstrappers

  [access "refs/meta/config"]
  read = group Project Owners

  [capability]
  administrateServer = group Administrators
  createProject = group Project Bootstrappers
  priority = batch group Non-Interactive Users
  runAs = group Project Bootstrappers
  streamEvents = group Registered Users

  [contributor-agreement "ICLA"]
  accepted = group CLA Accepted - ICLA
  agreementUrl = static/cla.html
  autoVerify = group CLA Accepted - ICLA
  description = OpenStack Individual Contributor License Agreement
  requireContactInformation = true

  [contributor-agreement "System CLA"]
  accepted = group System CLA
  agreementUrl = static/system-cla.html
  description = DON'T SIGN THIS: System CLA (externally managed)

  [contributor-agreement "USG CLA"]
  accepted = group USG CLA
  agreementUrl = static/usg-cla.html
  description = DON'T SIGN THIS: U.S. Government CLA (externally managed)

  [label "Code-Review"]
  abbreviation = R
  copyAllScoresOnTrivialRebase = true
  copyMinScore = true
  function = MaxWithBlock
  value = -2 Do not merge
  value = -1 I would prefer that you didn't merge this
  value = 0 No score
  value = +1 Looks good to me, but someone else must approve
  value = +2 Looks good to me (core reviewer)

  [label "Verified"]
  function = MaxWithBlock
  value = -2 Fails
  value = -1 Doesn't seem to work
  value = 0 No score
  value = +1 Works for me
  value = +2 Verified

  [label "Workflow"]
  function = MaxWithBlock
  value = -1 Work in progress
  value = 0 Ready for reviews
  value = +1 Approved

  [project]
  description = Rights inherited by all other projects


Each project should contain its own security users group to
allow the VMT group to assign users to review security patches.

An example of Nova's `project.config` should look like::

  [access "refs/heads/*"]
  label-Code-Review = -2..+2 group nova-security-users
  label-Workflow = -1..0 group nova-security-users

  [receive]
  requireChangeId = true
  requireContributorAgreement = true
