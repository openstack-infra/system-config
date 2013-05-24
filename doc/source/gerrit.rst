:title: Gerrit

Gerrit
######

Gerrit is the code review system used by the OpenStack project.  For a
full description of how the system fits into the OpenStack workflow,
see `the GerritJenkinsGithub wiki article
<https://wiki.openstack.org/wiki/GerritJenkinsGithub>`_.

This section describes how Gerrit is configured for use in the
OpenStack project and the tools used to manage that configuration.

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

  mysql -u root -p
  use reviewdb;
  insert into approval_categories values ('Approved', 'A', 2, 'MaxNoBlock', 'N', 'APRV');
  insert into approval_category_values values ('No score', 'APRV', 0);
  insert into approval_category_values values ('Approved', 'APRV', 1);
  update approval_category_values set name = "Looks good to me (core reviewer)" where name="Looks good to me, approved";

Expand "Verified" review type to -2/+2:

.. code-block:: mysql

  mysql -u root -p
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

  mysql -u root -p
  use reviewdb;
  update approval_category_values set name="Do not merge"
    where category_id='CRVW' and value=-2;
  update approval_category_values
    set name="I would prefer that you didn't merge this"
    where category_id='CRVW' and value=-1;

Add information about the CLA:

.. code-block:: mysql

  insert into contributor_agreements values (
  'Y', 'Y', 'Y', 'ICLA',
  'OpenStack Individual Contributor License Agreement',
  'static/cla.html', 2);

Groups
------

A number of system-wide groups are configured in Gerrit.  These
include `Project Bootstrappers` which grants all the permissions
needed to set up a new project.  Normally the OpenStack Project
Creater account is the only member of this group, but members of the
`Administrators` group may temporarily add themselves in order to
correct problems with automatic project creation.

The `External Testing Tools` group is used to grant +/-1 Verified
access to external testing tools.


GitHub Integration
==================

Gerrit replicate to GitHub by pushing to a standard Git remote.  The
GitHub projects are configured to allow only the Gerrit user to push.
This is handled automatically by :ref:`jeepyb`.


Auto Review Expiry
==================

Puppet automatically installs a daily cron job called ``expire-old-reviews``
onto the gerrit servers.  This script follows two rules:

 #. If the review hasn't been touched in 2 weeks, mark as abandoned.
 #. If there is a negative review and it hasn't been touched in 1 week, mark as
    abandoned.

If your review gets touched by either of these rules it is possible to
unabandon a review on the gerrit web interface.


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


Creating a new Gerrit Project with Puppet
=========================================

Gerrit project creation is now managed through changes to the
openstack-infra/config repository. The old manual processes are documented
below as the processes are still valid and documentation of them may
still be useful when dealing with corner cases. That said, you should
use this method whenever possible.

Puppet and its related scripts are able to create the new project in
Gerrit, create the new project on Github, create a local git replica on
the Gerrit host, configure the project Access Controls, and create new
groups in Gerrit that are mentioned in the Access Controls. You might
also want to configure Zuul and Jenkins to run tests on the new project.
The details for that process are in the next section.

Gerrit projects are configured in the
``openstack-infra/config:modules/openstack_project/templates/review.projects.yaml.erb``.
file. This file contains two sections, the first is a set of default
config values that each project can override, and the second is a list
of projects (each may contain their own overrides).


#. Config default values::

     - homepage: http://example.org
       local-git-dir: /var/lib/git
       gerrit-host: review.example.org
       gerrit-user: example-project-creator
       gerrit-key: /home/gerrit2/.ssh/example_project_id_rsa
       github-config: /etc/github/github-projects.secure.config
       has-wiki: False
       has-issues: False
       has-pull-requests: False
       has-downloads: False

#. Project definition::

     - project: example/gerrit
       description: Fork of Gerrit used by Example
       remote: https://gerrit.googlesource.com/gerrit
     - project: example/project1
       description: Best project ever.
       has-wiki: True
       acl-config: /path/to/acl/file

The above config gives puppet and its related scripts enough information
to create new projects, but not enough to add access controls to each
project. To add access control you need to have have an ``acl-config``
option for the project in ``review.projects.yaml.erb`` file. That option
should have a value that is a path to the project.config for that
project.

That is the high level view of how we can configure projects using the
pupppet repository. To create an actual change that does all of this for
a single project you will want to do the following:

#. Add a ``modules/openstack_project/files/gerrit/acls/project-name.config``
   file to the repo. You can refer to the :ref:`project-config` section
   below if you need more details on writing the project.config file,
   but contents will probably end up looking like the below block (note
   that the sections are in alphabetical order and each indentation is
   8 spaces)::

     [access "refs/heads/*"]
             label-Code-Review = -2..+2 group project-name-core
             label-Approved = +0..+1 group project-name-core
             workInProgress = group project-name-core
     [access "refs/heads/milestone-proposed"]
             label-Code-Review = -2..+2 group project-name-milestone
             label-Approved = +0..+1 group project-name-milestone
     [project]
             state = active
     [receive]
             requireChangeId = true
             requireContributorAgreement = true
     [submit]
             mergeContent = true

#. Add a project entry for the project in
   ``openstack-infra/config:modules/openstack_project/templates/review.projects.yaml.erb``.::

     - project: openstack/project-name
       acl-config: /home/gerrit2/acls/project-name.config

#. If there is an existing repo that is being replaced by this new
   project you can set the upstream value for the project. When an
   upstream is set, that upstream will be cloned and pushed into Gerrit
   instead of an empty repository. eg::

     - project: openstack/project-name
       acl-config: /home/gerrit2/acls/project-name.config
       upstream: git://github.com/awesumsauce/project-name.git

That is all you need to do. Push the change to gerrit and if necessary
modify group membership for the groups you configured in the
``project.config`` through Launchpad.

Have Zuul Monitor a Gerrit Project
=====================================

Define the required jenkins jobs for this project using the Jenkins Job
Builder. Edit openstack-infra/config:modules/openstack_project/files/jenkins_job_builder/config/projects.yaml
and add the desired jobs. Most projects will use the python jobs template.

A minimum config::

  - project:
      name: PROJECT
      github-org: openstack
      node: precise
      tarball-site: tarballs.openstack.org
      doc-publisher-site: docs.openstack.org

      jobs:
        - python-jobs

Full example config for nova::

  - project:
      name: nova
      github-org: openstack
      node: precise
      tarball-site: tarballs.openstack.org
      doc-publisher-site: docs.openstack.org

      jobs:
        - python-jobs
        - python-diablo-bitrot-jobs
        - python-essex-bitrot-jobs
        - openstack-publish-jobs
        - gate-{name}-pylint

Edit openstack-infra/config:modules/openstack_project/files/zuul/layout.yaml
and add the required jenkins jobs to this project. At a minimum you will
probably need the gate-PROJECT-merge test in the check and gate queues.

A minimum config::

  - name: openstack/PROJECT
      check:
        - gate-PROJECT-merge:
      gate:
        - gate-PROJECT-merge:

Full example config for nova::

  - name: openstack/nova
      check:
        - gate-nova-merge:
        - gate-nova-docs
        - gate-nova-pep8
        - gate-nova-python26
        - gate-nova-python27
        - gate-tempest-devstack-vm
        - gate-tempest-devstack-vm-cinder
        - gate-nova-pylint
      gate:
        - gate-nova-merge:
        - gate-nova-docs
        - gate-nova-pep8
        - gate-nova-python26
        - gate-nova-python27
        - gate-tempest-devstack-vm
        - gate-tempest-devstack-vm-cinder
      post:
        - nova-branch-tarball
        - nova-coverage
        - nova-docs
      pre-release:
        - nova-tarball
      publish:
        - nova-tarball
        - nova-docs

Creating a Project in Gerrit
============================

Using ssh key of a gerrit admin (you)::

  ssh -p 29418 review.openstack.org gerrit create-project --name openstack/PROJECT

If the project is an API project (eg, image-api), we want it to share
some extra permissions that are common to all API projects (eg, the
OpenStack documentation coordinators can approve changes, see
:ref:`acl`).  Run the following command to reparent the project if it
is an API project::

  ssh -p 29418 review.openstack.org gerrit set-project-parent --parent API-Projects openstack/PROJECT

Add yourself to the "Project Bootstrappers" group in Gerrit which will
give you permissions to push to the repo bypassing code review.

Do the initial push of the project with::

  git push ssh://USERNAME@review.openstack.org:29418/openstack/PROJECT.git HEAD:refs/heads/master
  git push --tags ssh://USERNAME@review.openstack.org:29418/openstack/PROJECT.git

Remove yourself from the "Project Bootstrappers" group, and then set
the access controls as specified in :ref:`acl`.

Create a Project in GitHub
==========================

As a github openstack admin:

* Visit https://github.com/organizations/openstack
* Click New Repository
* Visit the gerrit team admin page
* Add the new repository to the gerrit team

Pull requests can not be disabled for a project in Github, so instead
we have a script that runs from cron to close any open pull requests
with instructions to use Gerrit.

* Edit openstack-infra/config:modules/openstack_project/templates/review.projects.yaml.erb

and add the project to the list of projects in the yaml file

For example::

  - project: openstack/PROJECT

Adding Local Git Replica
========================

Gerrit replicates all repos to a local directory so that Apache can
serve the anonymous http requests out directly.

On the gerrit host::

  sudo git --bare init /var/lib/git/openstack/PROJECT.git
  sudo chown -R gerrit2:gerrit2 /var/lib/git/openstack/PROJECT.git

Adding A New Project On The Command Line
****************************************

All of the steps involved in adding a new project to Gerrit can be
accomplished via the commandline, with the exception of creating a new repo
on github.

First of all, add the .gitreview file to the repo that will be added. Then,
assuming an ssh config alias of `review` for the gerrit instance, as a person
in the Project Bootstrappers group::

     ssh review gerrit create-project --name openstack/$PROJECT
     git review -s
     git push gerrit HEAD:refs/heads/master
     git push --tags gerrit

At this point, the branch contents will be in gerrit, and the project config
settings and ACLs need to be set. These are maintained in a special branch
inside of git in gerrit. Check out the branch from git::

     git fetch gerrit +refs/meta/*:refs/remotes/gerrit-meta/*
     git checkout -b config remotes/gerrit-meta/config

There will be two interesting files, `groups` and `project.config`. `groups`
contains UUIDs and names of groups that will be referenced in
`project.config`. UUIDs can be found on the group page in gerrit.
Next, edit `project.config` to look like::

      [access "refs/*"]
              owner = group Administrators
      [receive]
              requireChangeId = true
              requireContributorAgreement = true
      [submit]
              mergeContent = true
      [access "refs/heads/*"]
              label-Code-Review = -2..+2 group $PROJECT-core
              label-Approved = +0..+1 group $PROJECT-core
      [access "refs/heads/milestone-proposed"]
              label-Code-Review = -2..+2 group $PROJECT-milestone
              label-Approved = +0..+1 group $PROJECT-milestone

If the project is for a client library, the `refs/*` section of
`project.config` should look like::

      [access "refs/*"]
              owner = group Administrators
              create = group $PROJECT-milestone
              pushTag = group $PROJECT-milestone

Replace $PROJECT with the name of the project.

Finally, commit the changes and push the config back up to Gerrit::

      git commit -m "Initial project config"
      git push gerrit HEAD:refs/meta/config

At this point you can follow the steps above for creating the project's github
replica, the local git replica, and zuul monitoring/jenkins jobs.

Migrating a Project from bzr
============================

Add the bzr PPA and install bzr-fastimport:

  add-apt-repository ppa:bzr/ppa
  apt-get update
  apt-get install bzr-fastimport

Doing this from the bzr PPA is important to ensure at least version 0.10 of
bzr-fastimport.

Clone the git-bzr-ng from termie:

  git clone https://github.com/termie/git-bzr-ng.git

In git-bzr-ng, you'll find a script, git-bzr. Put it somewhere in your path.
Then, to get a git repo which contains the migrated bzr branch, run:

  git bzr clone lp:${BRANCHNAME} ${LOCATION}

So, for instance, to do glance, you would do:

  git bzr clone lp:glance glance

And you will then have a git repo of glance in the glance dir. This git repo
is now suitable for uploading in to gerrit to become the new master repo.

.. _project-config:

Project Config
**************

There are a few options which need to be enabled on the project in the Admin
interface.

* Merge Strategy should be set to "Merge If Necessary"
* "Automatically resolve conflicts" should be enabled
* "Require Change-Id in commit message" should be enabled
* "Require a valid contributor agreement to upload" should be enabled

Optionally, if the PTL agrees to it:

* "Require the first line of the commit to be 50 characters or less" should
  be enabled.

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
#. Members of openstack-release (Release Manager and PTLs), and
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
        -2/+2 openstack-release
        -1/+1 registered users
      label approved (exclusive): 0/+1: openstack-release
      owner: openstack-release

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

Renaming a Project
******************

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

#. Make the project inacessible by editing the Access pane. Add a
   "read" ACL for "Administrators", and mark it "exclusive". Be sure
   to save changes.

#. Update the database on review.openstack.org::

     sudo mysql --defaults-file=/etc/mysql/debian.cnf reviewdb

     update account_project_watches
     set project_name = "openstack/NEW"
     where project_name = "openstack/OLD";

     update changes
     set dest_project_name = "openstack/NEW"
     where dest_project_name = "openstack/OLD";

#. Take Jenkins offline through its WebUI.

#. Stop Gerrit on review.openstack.org and move both the Git
   repository and the mirror::

     sudo invoke-rc.d gerrit stop
     sudo mv ~gerrit2/review_site/git/openstack/{OLD,NEW}.git
     sudo mv /var/lib/git/openstack/{OLD,NEW}.git
     sudo invoke-rc.d gerrit start

#. Bring Jenkins online through its WebUI.

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

#. Wait for puppet changes to be applied so that the earlier
   restrictive ACL will be reset for you (ending the outage for this
   project).

#. Submit a change that updates .gitreview with the new location of the
   project.

Developers will either need to re-clone a new copy of the repository,
or manually update their remotes with something like::

  git remote set-url origin https://github.com/$ORG/$PROJECT.git

Deleting a User from Gerrit
***************************

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

