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
  * http://review-security.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/review_security.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/review-security.projects.yaml.erb`
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

#. User does git clone from review-security.o.o
#. User does git review patch to review-security.o.o
#. The patch is review-able by member of VMT group, change owner and
   any manually added reviewer.
#. The patch is reviewed and approved on review-security.o.o
#. The patch is copied from review-security.o.o to public review.o.o
     a. git review -d patch from review-security.o.o
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
#. Vulnerability Managers can tag releases (push annotated tags).
#. Vulnerability Managers can add and remove users from Security Users group.

The `All-Projects.config` should look like::

  [project]
      description = Rights inherited by all other projects
  [access "refs/*"]
      read = group Anonymous Users
      pushTag = group Project Bootstrappers
      forgeAuthor = group Registered Users
      forgeCommitter = group Project Bootstrappers
      push = +force group Project Bootstrappers
      create = group Project Bootstrappers
      create = group Vulnerability Managers
      pushMerge = group Project Bootstrappers
      pushSignedTag = group Project Bootstrappers
  [access "refs/heads/*"]
      label-Code-Review = -1..+1 group Registered Users
      label-Workflow = -1..+0 group Change Owner
      submit = group Project Bootstrappers
  [access "refs/meta/config"]
      read = group Project Owners
  [access "refs/for/refs/*"]
      push = group Registered Users
  [capability]
      administrateServer = group Administrators
      priority = batch group Non-Interactive Users
      createProject = group Project Bootstrappers
      streamEvents = group Registered Users
      runAs = group Project Bootstrappers
  [label "Verified"]
      function = MaxWithBlock
      value = -2 Fails
      value = -1 Doesn't seem to work
      value =  0 No score
      value = +1 Works for me
      value = +2 Verified
  [label "Code-Review"]
      function = MaxWithBlock
      abbreviation = R
      copyMinScore = true
      copyAllScoresOnTrivialRebase = true
      copyAllScoresIfNoCodeChange = true
      value = -2 Do not merge
      value = -1 I would prefer that you didn't merge this
      value =  0 No score
      value = +1 Looks good to me, but someone else must approve
      value = +2 Looks good to me (core reviewer)
  [label "Workflow"]
      function = MaxWithBlock
      value = -1 Work in progress
      value =  0 Ready for reviews
      value = +1 Approved


Each project should contain it's own security users group to
allow the VMT group to assign users to review security patches.

An example of Nova's `project.config` should look like::

  [access "refs/heads/*"]
        label-Code-Review = -2..+2 group nova-security-users
        label-Workflow = -1..0 group nova-security-users
        abandon = group nova-security-users
  [receive]
        requireChangeId = true
        requireContributorAgreement = true
