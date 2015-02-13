:title: Gerrit

.. _gerrit:

Gerrit
######

Gerrit is the code review system used by the OpenStack project.  For a
full description of how the system fits into the OpenStack workflow,
see `the development workflow guide
<http://docs.openstack.org/infra/manual/developers.html#development-workflow>`_.

This section describes how Gerrit is configured for use in the
OpenStack project and the tools used to manage that configuration.

At a Glance
===========

:Hosts:
  * http://review.openstack.org
  * http://review-dev.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-gerrit/tree/
  * :file:`modules/openstack_project/manifests/review.pp`
  * :file:`modules/openstack_project/manifests/review_dev.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/review.projects.ini.erb`
  * :config:`gerrit/projects.yaml`
:Projects:
  * http://code.google.com/p/gerrit/
:Bugs:
  * https://storyboard.openstack.org/#!/project/715
  * http://code.google.com/p/gerrit/issues/list
:Resources:
  * `Gerrit Documentation <https://review.openstack.org/Documentation/index.html>`_

Installation
============

Gerrit is installed and configured by Puppet, including specifying the
exact Java WAR file that is used.  See :ref:`sysadmin` for how Puppet
is used to manage OpenStack infrastructure systems.

Cinder Volumes
--------------

The Gerrit installation at /home/gerrit2 is located on a Cinder
volume.  See :ref:`cinder` for details on volume management.  Note
that SSD volumes are used (and they have a minimum size of 100G).

Gerrit Configuration
--------------------

Most of Gerrit's configuration is in configuration files or Git
repositories (and in our case, managed by Puppet), but a few items
must be configured in the database.  The following is a record of
these changes:

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

The `Third-Party CI` group is used to grant +/-1 Verified
access to external testing tools on a sandbox project.

The `Voting Third-Party CI` group is used to grant +/-1 Verified
access to external testing tools for all projects.

The `Continuous Integration Tools` group contains Jenkins and any
other CI tools that get +2/-2 access on reviews.

The `Release Managers` group is used for release managers.


Users
-----

The first user to log in becomes an administrator. Be sure to set an
account name and add ssh keys - you'll need those.

Once you've created your groups you should create the
``openstack-project-creator`` account by hand (the account name is
referenced from
:file:`modules/openstack_project/templates/review.projects.ini.erb`)
using::

  cat $pubkey | ssh -p 29418 $USER@$HOST gerrit create-account \
    --group "'Project Bootstrappers'" \
    --group Administrators \
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

Note that the user running gerrit will need to accept the github host
keys. e.g.::

  sudo su - gerrit2
  ssh github.com


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
openstack-infra/system-config repository.  :ref:`jeepyb` handles
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
   changes to be merged on pre-release proposed/* branches.
#. Full code review (+/- 2) of API projects (documentation of the API,
   not implementation of the API) should be available to the -core
   group of the corresponding implementation project as well as to the
   OpenStack Documentation Coordinators.
#. Full code review of stable branches should be available to the
   -stable-maint group of the project.
#. Drivers (PTL and delegates) of client library projects should be
   able to add tags (which are automatically used to trigger
   releases).

To manage API project permissions collectively across projects, API
projects are reparented to the "API-Projects" meta-project instead of
"All-Projects".  This causes them to inherit permissions from the
API-Projects project (which, in turn, inherits from All-Projects).

The global gerrit permissions set out the high level goals (and
manage-projects can then override this on a per project basis as
needed). To setup the global permissions first create the groups
covered above under Groups.

You need to grant yourself enough access to replace the ACLs over ssh (we use
SSH because it's fast, and it gets syntax checked).

#. Visit ``https://$HOST/#/admin/projects/All-Projects,access`` and click on Edit.

#. Look for the reference to 'refs/meta/config', click on the drop-box
   for 'add permission' and choose 'PUSH'.

#. Type in Administrators as the group name

#. Click on Add

#. Click on Save Changes

Then... we need to fetch the All-Projects ACLs, update them, then push the
updates back into Gerrit::

  export USER=$your_gerrit_user
  export HOST=$your_gerrit_hos
  cd $anywhereyoulike
  mkdir All-Projects-ACLs
  cd All-Projects-ACLs
  git init
  git remote add gerrit ssh://$USER@$HOST:29418/All-Projects.git
  git fetch gerrit +refs/meta/*:refs/remotes/gerrit-meta/*
  git checkout -b config remotes/gerrit-meta/config

There will be two interesting files, `groups` and `project.config`.
`groups` contains UUIDs and names of groups that will be referenced
in `project.config`. UUIDs can be found on the group page in gerrit.
Next, edit `project.config` to look like::

  [access "refs/*"]
  create = group Project Bootstrappers
  create = group Release Managers
  forgeAuthor = group Registered Users
  forgeCommitter = group Project Bootstrappers
  push = +force group Project Bootstrappers
  pushMerge = group Project Bootstrappers
  pushSignedTag = group Project Bootstrappers
  pushTag = group Continuous Integration Tools
  pushTag = group Project Bootstrappers
  pushTag = group Release Managers
  read = group Anonymous Users

  [access "refs/drafts/*"]
  push = block group Registered Users

  [access "refs/for/refs/*"]
  push = group Registered Users

  [access "refs/for/refs/zuul/*"]
  pushMerge = group Continuous Integration Tools

  [access "refs/heads/*"]
  label-Code-Review = -2..+2 group Project Bootstrappers
  label-Code-Review = -1..+1 group Registered Users
  label-Verified = -2..+2 group Continuous Integration Tools
  label-Verified = -2..+2 group Project Bootstrappers
  label-Verified = -1..+1 group Voting Third-Party CI
  label-Workflow = -1..+0 group Change Owner
  label-Workflow = -1..+1 group Project Bootstrappers
  rebase = group Registered Users
  submit = group Continuous Integration Tools
  submit = group Project Bootstrappers

  [access "refs/heads/proposed/*"]
  exclusiveGroupPermissions = label-Code-Review label-Workflow
  label-Code-Review = -2..+2 group Project Bootstrappers
  label-Code-Review = -2..+2 group Release Managers
  label-Code-Review = -1..+1 group Registered Users
  label-Workflow = +0..+1 group Project Bootstrappers
  label-Workflow = +0..+1 group Release Managers
  owner = group Release Managers

  [access "refs/meta/config"]
  read = group Project Owners

  [access "refs/meta/openstack/*"]
  create = group Continuous Integration Tools
  push = group Continuous Integration Tools
  read = group Continuous Integration Tools

  [access "refs/zuul/*"]
  create = group Continuous Integration Tools
  push = +force group Continuous Integration Tools
  pushMerge = group Continuous Integration Tools

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
  value = -1 This patch needs further work before it can be merged
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

Now edit the groups file. The format is::

  #UUID  Group Name
  1234567890123456789012345678901234567890  group-foo

Each of the groups listed above under 'Groups' should have an entry as well as
the built in groups such as 'Non-Interactive Users' which may or may not be
present in the initial groups file. You can find the UUID values by navigating
to Admin -> Groups -> Group Name -> General in the Web UI.

Finally, commit the changes and push the config back up to Gerrit::

  git commit -am "Initial All-Projects config"
  git push gerrit HEAD:refs/meta/config


Manual Administrative Tasks
===========================

The following sections describe tasks that individuals with root
access may need to perform on rare occasions.


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

#. Stop puppet runs on the puppetmaster to prevent early application
   of configuration changes::

     sudo crontab -u root -e

   Comment out the crontab entries.  Use ps to make sure that a run is
   not currently in progress.  When it finishes, make sure the entry
   has not been added back to the crontab.

#. Gracefully stop Zuul on zuul.openstack.org::

     sudo kill -USR1 $(cat /var/run/zuul/zuul.pid)
     rm -f /var/run/zuul/zuul.pid /var/run/zuul/zuul.lock

#. Stop Gerrit on review.openstack.org::

     sudo invoke-rc.d gerrit stop

#. Update the database on review.openstack.org::

     sudo -H mysql reviewdb

     update account_project_watches
     set project_name = "openstack/NEW"
     where project_name = "openstack/OLD";

     update changes
     set dest_project_name = "openstack/NEW", created_on = created_on
     where dest_project_name = "openstack/OLD";

#. Move both the git repository and the mirror on
   review.openstack.org::

     sudo mv ~gerrit2/review_site/git/openstack/{OLD,NEW}.git
     sudo mv /opt/lib/git/openstack/{OLD,NEW}.git

#. Reindex the lucene search index on review.openstack.org::

     sudo su - gerrit2
     cp -ax review_site/index index.backup.`date +%s`
     java -jar review_site/bin/gerrit.war reindex -d /home/gerrit2/review_site

#. Move the git repository on git{01-05}.openstack.org (while the
   lucene reindex is running)::

     sudo mv /var/lib/git/openstack/{OLD,NEW}.git

#. Rename the project or transfer ownership in GitHub (while the
   lucene reindex is running).

#. Start Gerrit on review.openstack.org::

     sudo invoke-rc.d gerrit start

#. Start Zuul on zuul.openstack.org::

     sudo invoke-rc.d zuul start

#. Rename any associated groups whose names may have changed::

     ssh -p 29418 review.openstack.org gerrit rename-group OLDNAME NEWNAME

#. If renamed/transfered projects using StoryBoard, update the db:

     update projects set name='stackforge/NEW' where name='openstack/OLD';

#. Merge the prepared Puppet configuration change, removing the
   original Jenkins jobs via the Jenkins WebUI later if needed.

#. Re-enable puppet runs on the puppetmaster::

     sudo crontab -u root -e

#. If this is an org move and the project name itself is not
   changing, gate jobs may fail due to outdated remote URLs. Clear
   the workspaces on persistent Jenkins slaves to mitigate this::

     sudo ansible-playbook -f 10 /etc/ansible/playbooks/clean_workspaces.yaml --extra-vars "project=PROJECTNAME"

#. Submit a change that updates .gitreview with the new location of the
   project.

Developers will either need to re-clone a new copy of the repository,
or manually update their remotes with something like::

  git remote set-url origin https://git.openstack.org/$ORG/$PROJECT


Third-Party Testing Access
--------------------------

The command to add an account for an automated system which gets -1/+1
code verify voting rights (as outlined in :ref:`third-party-testing`)
looks like:

.. code-block:: bash

  ssh -p 29418 review.openstack.org "gerrit create-account \
      --group 'Third-Party CI' \
      --full-name 'Some CI Bot' \
      --email ci-bot@third-party.org \
      --ssh-key 'ssh-rsa AAAAB3Nz...zaUCse1P ci-bot@third-party.org' \
      some-ci-bot"

Details on the create-account_ command can be found in the Gerrit
API documentation.

.. _create-account: https://review.openstack.org/Documentation/cmd-create-account.html

Resetting a Username in Gerrit
------------------------------

Initially if a Gerrit username (which is used to associate SSH
connections to an account) has not yet been set, the user can type
it into the Gerrit WebUI... but there is no supported way for the
user to alter or correct it once entered. Further, if a defunct
account has the desired username, a different one will have to be
entered.

Because of this, often due to the user ending up with `Duplicate
Accounts in Gerrit`_, it may be requested to change the SSH username
of an account. Confirm the account_id number for the account in
question and remove the existing username external_id for that (it
may also be necessary to remove any lingering external_id with the
desired username if confirmed there is a defunct account associated
with it):

.. code-block:: mysql

  delete from account_external_ids where account_id=NNNN and external_id like 'username:%';

After this, the user should be able to re-add their username through
the Gerrit WebUI.


Duplicate Accounts in Gerrit
----------------------------

From time to time, outside events affecting SSO authentication or
identity changes can result in multiple Gerrit accounts for the same
user. This frequently causes duplication of preferred E-mail
addresses, which also renders the accounts unselectable in some
parts of the WebUI (notably when trying to add reviewers to a change
or members in a group). Gerrit does not provide a supported
mechanism for `Combining Gerrit Accounts`_, and doing so manually is
both time-consuming and error prone. As a result, the OpenStack
infrastructure team does not combine duplicate accounts for users
but can clean up these E-mail address issues upon request. To find
the offending duplicates:

.. code-block:: mysql

  select account_id from accounts where preferred_email='user@example.com';

Find out from the user which account_id is the one they're currently
using, and then null out the others with:

.. code-block:: mysql

  update accounts set preferred_email=NULL, registered_on=registered_on where account_id=OLD;

Then flush Gerrit's caches so any immediate account lookups will hit
the current DB contents:

.. code-block:: bash

  ssh review.openstack.org -p29418 gerrit flush-caches --all


Combining Gerrit Accounts
-------------------------

While not supported by Gerrit, a fairly thorough account merge is
documented here (mostly as a demonstration of its unfortunate
complexity). Please note that the OpenStack infrastructure team does
not combine duplicate accounts for users upon request, but this
would be the process to follow if it becomes necessary under some
extraordinary circumstance.

Collect as much information as possible about all affected accounts,
and then go poking around in the tables listed below for additional
ones to determine the account_id number for the current account and
any former accounts which should be merged into it. Then for each
old account_id, perform these update and delete queries:

.. code-block:: mysql

  delete from account_agreements where account_id=OLD;
  delete from account_diff_preferences where id=OLD;
  delete from account_external_ids where account_id=OLD;
  delete from account_group_members where account_id=OLD;
  delete from account_group_members_audit where account_id=OLD;
  delete from account_project_watches where account_id=OLD;
  delete from account_ssh_keys where account_id=OLD;
  delete from accounts where account_id=OLD;
  update account_patch_reviews set account_id=NEW where account_id=OLD;
  update starred_changes set account_id=NEW where account_id=OLD;
  update change_messages set author_id=NEW, written_on=written_on where author_id=OLD;
  update changes set owner_account_id=NEW, created_on=created_on where owner_account_id=OLD;
  update patch_comments set author_id=NEW, written_on=written_on where author_id=OLD;
  update patch_sets set uploader_account_id=NEW, created_on=created_on where uploader_account_id=OLD;
  update patch_set_approvals set account_id=NEW, granted=granted where account_id=OLD;

If that last update query results in a collision with an error
like::

  ERROR 1062 (23000): Duplicate entry 'XXX-YY-NEW' for key 'PRIMARY'

Then you can manually delete the old approval:

.. code-block:: mysql

  delete from patch_set_approvals where account_id=OLD and change_id=XXX and patch_set_id=YY;

And repeat until the update query runs to completion.

After all the described deletes and updates have been applied, flush
Gerrit's caches so things like authentication will be rechecked
against the current DB contents:

.. code-block:: bash

  ssh review.openstack.org -p29418 gerrit flush-caches --all

Make the user aware that these steps have also removed any group
memberships, preferences, SSH keys, contact information, CLA
signatures, and so on associated with the old account so some of
these may still need to be added to the new one via the Gerrit WebUI
if they haven't been already. With a careful inspection of all
accounts involved it is possible to merge some information from the
old accounts into new ones by performing update queries similar to
the deletes above, but since this varies on a case-by-case basis
it's left as an exercise for the reader.


Deleting a User from Gerrit
---------------------------

This isn't normally necessary, but if you find that you need to
completely delete an account from Gerrit, perform the same delete
queries mentioned in `Combining Gerrit Accounts`_ and replace the
update queries for account_patch_reviews and starred_changes with:

.. code-block:: mysql

  delete from account_patch_reviews where account_id=OLD;
  delete from starred_changes where account_id=OLD;

The other update queries can be ignored, since deleting them in many
cases would result in loss of legitimate review history.
