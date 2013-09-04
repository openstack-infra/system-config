:title: Gerrit

.. _gerrit:

Gerrit
######

Gerrit is the code review system used by the OpenStack project.  For a
full description of how the system fits into the OpenStack workflow,
see `the GerritJenkinsGit wiki article
<https://wiki.openstack.org/wiki/GerritJenkinsGit>`_.

This section describes how Gerrit is configured for use in the
OpenStack project and the tools used to manage that configuration.

At a Glance
===========

:Hosts:
  * http://review.openstack.org
  * http://review-dev.openstack.org
:Puppet:
  * :file:`modules/gerrit`
  * :file:`modules/openstack_project/manifests/review.pp`
  * :file:`modules/openstack_project/manifests/review_dev.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/review.projects.yaml.erb`
:Projects:
  * http://code.google.com/p/gerrit/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * http://code.google.com/p/gerrit/issues/list
:Resources:
  * `Gerrit Documentation <https://review.openstack.org/Documentation/index.html>`_

Installation
============

Gerrit is installed and configured by Puppet, including specifying the
exact Java WAR file that is used.  See :ref:`sysadmin` for how Puppet
is used to manage OpenStack infrastructure systems.

Gerrit Configuration
--------------------

Most of Gerrit's configuration is in configuration files or Git
repositories (and in our case, managed by Puppet), but a few items
must be configured in the database.  The following is a record of
these changes:

Add "Approved" review type to gerrit:

.. code-block:: mysql

  sudo -u root
  mysql
  use reviewdb;
  insert into approval_categories values ('Approved', 'A', 2, 'MaxNoBlock', 'N', 'APRV');
  insert into approval_category_values values ('No score', 'APRV', 0);
  insert into approval_category_values values ('Approved', 'APRV', 1);
  update approval_category_values set name = "Looks good to me (core reviewer)" where name="Looks good to me, approved";

Expand "Verified" review type to -2/+2:

.. code-block:: mysql

  sudo -u root
  mysql
  use reviewdb;
  update approval_category_values set value=2
    where value=1 and category_id='VRIF';
  update approval_category_values set value=-2
    where value=-1 and category_id='VRIF';
  insert into approval_category_values values
    ("Doesn't seem to work","VRIF",-1),
    ("Works for me","VRIF","1");

Reword the default messages that use the word Submit, as they imply that
we're not happy with people for submitting the patch in the first place:

.. code-block:: mysql

  sudo -u root
  mysql
  use reviewdb;
  update approval_category_values set name="Do not merge"
    where category_id='CRVW' and value=-2;
  update approval_category_values
    set name="I would prefer that you didn't merge this"
    where category_id='CRVW' and value=-1;

Add information about the CLA:

.. code-block:: mysql

  sudo -u root
  mysql
  use reviewdb;
  insert into contributor_agreements values (
  'Y', 'Y', 'Y', 'ICLA',
  'OpenStack Individual Contributor License Agreement',
  'static/cla.html', 2);

Groups
------

A number of system-wide groups are configured in Gerrit (rather than
via Puppet).  When installing a new Gerrit you should create these by
hand (and capture their UUID - you will need them to setup the ACLs
later).

The `Project Bootstrappers` group grants all the permissions needed to
set up a new project.  Normally the OpenStack Project Creater account
is the only member of this group, but members of the `Administrators`
group may temporarily add themselves in order to correct problems with
automatic project creation.

The `External Testing Tools` group is used to grant +/-1 Verified
access to external testing tools.

The `Continuous Integration Tools` group contains Jenkins and any
other CI tools that get +2/-2 access on reviews.

The `Release Managers` group is used for release managers.

The `Stable Maintainers` group is used for people maintaining stable
branches - often distinct from the folk maintaining projects.


Users
-----

The first user to log in becomes an administrator. Be sure to set an
account name and add ssh keys - you'll need those.

You should create the ``openstack-project-creator`` account by hand
(referenced from
:file:`modules/openstack_project/templates/review.projects.yaml.erb`)
using::

  cat $pubkey | gerrit create-account --group "'Project Bootstrappers'" \
    --full-name "'Project Creator'" \
    --email openstack-infra@lists.openstack.org \
    --ssh-key - openstack-project-creator

GitHub Integration
==================

Gerrit replicate to GitHub by pushing to a standard Git remote.  The
GitHub projects are configured to allow only the Gerrit user to push.

Pull requests can not be disabled for a project in Github, so instead
we have a script that runs from cron to close any open pull requests
with instructions to use Gerrit.

These are both handled automatically by :ref:`jeepyb`.


Auto Review Expiry
==================

Puppet automatically installs a daily cron job called ``expire-old-reviews``
onto the gerrit servers.  This script follows two rules:

 #. If the review hasn't been touched in 2 weeks, mark as abandoned.
 #. If there is a negative review and it hasn't been touched in 1 week, mark as
    abandoned.

If your review gets touched by either of these rules it is possible to
unabandon a review on the gerrit web interface.

This process is managed by the :ref:`jeepyb` openstack-infra project.

Gerrit IRC Bot
==============

Gerritbot consumes the Gerrit event stream and announces relevant
events on IRC.  :ref:`gerritbot` is an openstack-infra project and is
also available on Pypi.


Launchpad Bug Integration
=========================

In addition to the hyperlinks provided by the regex in gerrit.config,
we use a Gerrit hook to update Launchpad bugs when changes referencing
them are applied.  This is managed by the :ref:`jeepyb`
openstack-infra project.


New Project Creation
====================

Gerrit project creation is now managed through changes to the
openstack-infra/config repository.  :ref:`jeepyb` handles
automatically creating any new projects defined in the configuration
files.

Local Git Replica
=================

Gerrit replicates all repos to a local directory so that Apache can
serve the anonymous http requests out directly.  This is automatically
configured by :ref:`jeepyb`.

.. _acl:

Access Controls
===============

High level goals:

#. Anonymous users can read all projects.
#. All registered users can perform informational code review (+/-1)
   on any project.
#. Jenkins can perform verification (blocking or approving: +/-1).
#. All registered users can create changes.
#. The OpenStack Release Manager and Jenkins can tag releases (push
   annotated tags).
#. Members of $PROJECT-core group can perform full code review
   (blocking or approving: +/- 2), and submit changes to be merged.
#. Members of Release Managers (Release Manager and delegates), and
   $PROJECT-milestone (PTL and release minded people) exclusively can
   perform full code review (blocking or approving: +/- 2), and submit
   changes to be merged on milestone-proposed branches.
#. Full code review (+/- 2) of API projects should be available to the
   -core group of the corresponding implementation project as well as to
   the OpenStack Documentation Coordinators.
#. Full code review of stable branches should be available to the
   -core group of the project as well as the openstack-stable-maint
   group.
#. Drivers (PTL and delegates) of client library projects should be
   able to add tags (which are automatically used to trigger
   releases).

To manage API project permissions collectively across projects, API
projects are reparented to the "API-Projects" meta-project instead of
"All-Projects".  This causes them to inherit permissions from the
API-Projects project (which, in turn, inherits from All-Projects).

These permissions try to achieve the high level goals::

  All Projects (metaproject):
    refs/*
      read: anonymous
      push annotated tag: release managers, ci tools, project bootstrappers
      forge author identity: registered users
      forge committer identity: project bootstrappers
      push (w/ force push): project bootstrappers
      create reference: project bootstrappers, release managers
      push merge commit: project bootstrappers

    refs/for/refs/*
      push: registered users

    refs/heads/*
      label code review:
        -1/+1: registered users
        -2/+2: project bootstrappers
      label verified:
        -2/+2: ci tools
        -2/+2: project bootstrappers
        -1/+1: external tools
      label approved 0/+1: project bootstrappers
      submit: ci tools
      submit: project bootstrappers

    refs/heads/milestone-proposed
      label code review (exclusive):
        -2/+2 Release Managers
        -1/+1 registered users
      label approved (exclusive): 0/+1: Release Managers
      owner: Release Managers

    refs/heads/stable/*
      label code review (exclusive):
        -2/+2 opestack-stable-maint
        -1/+1 registered users
      label approved (exclusive): 0/+1: opestack-stable-maint

    refs/meta/*
      push: project bootstrappers

    refs/meta/config
      read: project bootstrappers
      read: project owners

  API Projects (metaproject):
    refs/*
      owner: Administrators

    refs/heads/*
      label code review -2/+2: openstack-doc-core
      label approved 0/+1: openstack-doc-core

  project foo:
    refs/*
      owner: Administrators
      create reference: foo-milestone  [client library only]
      push annotated tag: foo-milestone  [client library only]

    refs/heads/*
      label code review -2/+2: foo-core
      label approved 0/+1: foo-core

    refs/heads/milestone-proposed
      label code review -2/+2: foo-milestone
      label approved 0/+1: foo-milestone

Manual Administrative Tasks
===========================

The following sections describe tasks that individuals with root
access may need to perform on rare occations.


Renaming a Project
------------------

Renaming a project is not automated and is disruptive to developers,
so it should be avoided. Allow for an hour of downtime for the
project in question, and about 10 minutes of downtime for all of
Gerrit. All Gerrit changes, merged and open, will carry over, so
in-progress changes do not need to be merged before the move.

To rename a project:

#. Prepare a change to the Puppet configuration which updates
   projects.yaml/ACLs and jenkins-job-builder for the new name.

#. Stop puppet on review.openstack.org to prevent your interim
   configuration changes from being reset by the project management
   routines::

     sudo puppetd --disable

#. Gracefully stop Zuul on zuul.openstack.org::

     sudo kill -USR1 $(cat /var/run/zuul/zuul.pid)
     rm -f /var/run/zuul/zuul.pid /var/run/zuul/zuul.lock

#. Stop Gerrit on review.openstack.org::

     sudo invoke-rc.d gerrit stop

#. Update the database on review.openstack.org::

     sudo mysql --defaults-file=/etc/mysql/debian.cnf reviewdb

     update account_project_watches
     set project_name = "openstack/NEW"
     where project_name = "openstack/OLD";

     update changes
     set dest_project_name = "openstack/NEW"
     where dest_project_name = "openstack/OLD";

#. Move both the git repository and the mirror on
   review.openstack.org::
   
     sudo mv ~gerrit2/review_site/git/openstack/{OLD,NEW}.git
     sudo mv /var/lib/git/openstack/{OLD,NEW}.git

#. Move the git repository on git.openstack.org::

     sudo mv /var/lib/git/openstack/{OLD,NEW}.git

#. Start Gerrit on review.openstack.org::

     sudo invoke-rc.d gerrit start

#. Start Zuul on zuul.openstack.org::

     sudo invoke-rc.d zuul start

#. Merge the prepared Puppet configuration change, removing the
   original Jenkins jobs via the Jenkins WebUI later if needed.

#. Start puppet again on review.openstack.org::

     sudo puppetd --enable

#. Rename the project in GitHub or, if this is a move to a new org, let
   the project management run create it for you and then remove the
   original later (assuming you have sufficient permissions).

#. If this is an org move and the project name itself is not
   changing, gate jobs may fail due to outdated remote URLs. Clear
   the workspaces on persistent Jenkins slaves to mitigate this::

     ssh -t $h.slave.openstack.org 'sudo rm -rf ~jenkins/workspace/*PROJECT*'

#. Again, if this is an org move rather than a rename and the GitHub
   project has been created but is empty, trigger replication to
   populate it::

     ssh -p 29418 review.openstack.org gerrit replicate --all

#. Submit a change that updates .gitreview with the new location of the
   project.

Developers will either need to re-clone a new copy of the repository,
or manually update their remotes with something like::

  git remote set-url origin https://git.openstack.org/$ORG/$PROJECT

Deleting a User from Gerrit
---------------------------

This isn't normally necessary, but if you find that you need to
completely delete an account from Gerrit, here's how:

.. code-block:: mysql

  delete from account_agreements where account_id=NNNN;
  delete from account_diff_preferences where id=NNNN;
  delete from account_external_ids where account_id=NNNN;
  delete from account_group_members where account_id=NNNN;
  delete from account_group_members_audit where account_id=NNNN;
  delete from account_patch_reviews where account_id=NNNN;
  delete from account_project_watches where account_id=NNNN;
  delete from account_ssh_keys where account_id=NNNN;
  delete from accounts where account_id=NNNN;

.. code-block:: bash

  ssh review.openstack.org -p29418 gerrit flush-caches --all

