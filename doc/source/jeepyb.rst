:title: Jeepyb

.. _jeepyb:

Jeepyb
######

Jeepyb is a collection of tools which make managing Gerrit easier.
Specifically, management of Gerrit projects and their associated
upstream integration with things like Github and Launchpad.

At a Glance
===========

:Hosts:
  * http://review.openstack.org
  * http://review-dev.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-jeepyb/tree/
  * :file:`modules/openstack_project/manifests/review.pp`
  * :file:`modules/openstack_project/manifests/review_dev.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/review.projects.ini.erb`
  * :config:`gerrit/projects.yaml`
  * :file:`modules/openstack_project/files/pypi-mirror.yaml`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/jeepyb
:Bugs:
  * https://storyboard.openstack.org/#!/project/722


Gerrit Project Configuration
============================

The ``manage-projects`` command in Jeepyb is able to create a new
project in Gerrit, create the new project on Github, create a local
git replica on the Gerrit host, configure the project Access Controls,
and create new groups in Gerrit.

The global configuration data needed for ``manage-projects`` to know how to
connect to things or how to operate is in
:file:`modules/openstack_project/templates/review.projects.ini.erb`.

#. Config values::

     [projects]
     homepage=http://example.org
     local-git-dir=/var/lib/git
     gerrit-host=review.example.org
     gerrit-user=example-project-creator
     gerrit-key=/home/gerrit2/.ssh/example_project_id_rsa
     github-config=/etc/github/github-projects.secure.config
     has-wiki=False
     has-issues=False
     has-pull-requests=False
     has-downloads=False

OpenStack Gerrit projects are configured in the
:config:`gerrit/projects.yaml`.  file.  When this file is updated,
``manage-projects`` is run automatically.

#. Project definition::

     - project: example/gerrit
       description: Fork of Gerrit used by Example
       remote: https://gerrit.googlesource.com/gerrit
     - project: example/project1
       description: Best project ever.
       has-wiki: True
       acl-config: /path/to/acl/file

The above config gives puppet and its related scripts enough
information to create new projects, but not enough to add access
controls to each project. To add access control you need to have an
``acl-config`` option for the project in ``projects.yaml``. That
option should have a value that is a path to the ``project.config``
for that project.

That is the high level view of how we can configure projects using the
pupppet repository. To create an actual change that does all of this for
a single project you will want to do the following:

#. Add a ``gerrit/acls/organization/project-name.config`` file to the
   ``project-config`` repo. The contents will probably end up looking like
   the block below (note that the sections are in alphabetical order)::

     [access "refs/heads/*"]
     label-Code-Review = -2..+2 group project-name-core
     label-Workflow = -1..+1 group project-name-core

     [access "refs/heads/proposed/*"]
     label-Code-Review = -2..+2 group project-name-release
     label-Workflow = -1..+1 group project-name-release

     [receive]
     requireChangeId = true
     requireContributorAgreement = true

     [submit]
     mergeContent = true

#. Add a project entry for the project in ``gerrit/projects.yaml`` in
   the ``project-config`` repo.::

     - project: organization/project-name
       acl-config: /home/gerrit2/acls/organization/project-name.config

#. If there is an existing repo that is being replaced by this new
   project you can set the upstream value for the project. When an
   upstream is set, that upstream will be cloned and pushed into Gerrit
   instead of an empty repository. eg::

     - project: organization/project-name
       acl-config: /home/gerrit2/acls/organization/project-name.config
       upstream: git://github.com/awesumsauce/project-name.git

That is all you need to do. Push the change to gerrit and if necessary
modify group membership for the groups you configured in the
``project.config`` through Launchpad.

Commit Hooks
============

Launchpad Bug Integration
-------------------------

The ``update-bug`` Jeepyb command is installed as a Gerrit commit hook
so that it runs each time a patchset is created.  It updates Launchpad
bugs based on information that it finds in the commit message.  It
also contains a manual mapping of Gerrit to Launchpad project names
for projects that use a different Launchpad project for their bugs.

Launchpad Blueprint Integration
-------------------------------

The ``update-blueprint`` Jeepyb command is installed as a Gerrit
commit hook so that it runs each time a patchset is created.  It
updates Launchpad blueprints based on information that it finds in the
commit message.

Impact Notification
-------------------

The ``notify-impact`` commit hook runs when new patchsets are created
and sends email notifications when certain regular expressions are
matched, such as:

* DocImpact
* SecurityImpact

Trivial Rebase Hook
-------------------

The ``trivial-rebase`` commit hook runs when new patchsets are
uploaded and detects whether the new patchset is merely a rebase onto
a new parent, or is a substantial change.  If it is a rebase, it
restores previous review votes and leaves a comment in Gerrit.  It
uses Gerrit's own SSH host key as the private key for access in order
to gain the "superuser" permissions needed to impersonate other users
in reviews.


Periodic Tasks
==============

Closing Github Pull Requests
----------------------------

The ``close-pull-requests`` Jeepyb command is installed as a cron job
and periodically closes all pull requests for projects so configured
in projects.yaml.


Expiring Old Reviews
--------------------

The ``expire-old-reviews`` Jeepyb command is installed as a cron job
that periodically marks reviews that have seen little activity as
`Abandoned`.  Their owners may use the Gerrit interface to restore
them when they are ready for further review.

Manage Projects
---------------

Some projects may have upstreams defined in Jeepyb; the
``manage-projects`` cron job will update these remotes so that their
commits are available in Gerrit. It will also ensure that project metadata
is set up as defined in projects.yaml.

RSS feeds
---------

Jeepyb's ``openstackwatch`` command publishes RSS feeds of Gerrit
projects.

Pypi Mirror
-----------

The ``run-mirror`` command builds a full Pypi mirror for a project or
set of projects by reading a requirements.txt file, installing all
listed dependencies into a virtualenv, inspecting the resulting
installed package set, and then downloading all of the second-level
(and further) dependencies.  Essentially, the mirror is built by
introspection and contains the full set of depedencies needed whether
they are explicitly listed or not.

Admin tasks
-----------

Jeepyb needs to run with the same ssh key registered with gerrit and github
(and any other ssh services it may be pointed at). Be sure to add your public
key when creating accounts.
