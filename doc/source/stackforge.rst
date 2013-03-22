:title: StackForge

StackForge
##########

StackForge is the way that OpenStack related projects can consume and
make use of the OpenStack project infrastructure. This includes Gerrit
code review, Jenkins continuous integration, GitHub repository
mirroring, and various small things like IRC bots, pypi uploads, RTFD
updates. Projects should make use of StackForge if they want to run
their project with Gerrit code review and have a trunk gated by Jenkins.

StackForge projects are expected to be self sufficient when it comes to
configuring Gerrit/Jenkins/Zuul etc. The openstack-infra team can
provide assistance as resources allow, but should not be relied on.

What StackForge is not:

* Official endorsement of a project by OpenStack.
* Access to a GitHub organization (StackForge projects are mirrored to
  GitHub, this is all the GitHub org is used for).
* A guarantee of eventual OpenStack incubation (Though it is a good
  first step in that process as it exposes the project to the OpenStack
  way of doing things).

Add a Project to StackForge
***************************

Request a Core Group in Gerrit
==============================

StackForge uses Gerrit for group management. The first step in
creating a StackForge project is to request a group in Gerrit called
``your-project-name-core``. Members of this team will have permissions
to approve code changes to your project, and to add other Gerrit users
to the group.

You can request Gerrit groups by opening a bug at
https://bugs.launchpad.net/openstack-ci/+filebug (make sure to mention
the Gerrit name or E-mail address of at least one initial member).

Create a new StackForge Project with Puppet
===========================================

OpenStack uses Puppet and a management script to create Gerrit projects
with simple changes to the openstack-infra/config repository. To start make
sure you have cloned the openstack-infra/config repository
``git clone https://github.com/openstack-infra/config``.

First you need to add your StackForge project to the master project
list. Edit
``openstack-infra/config/modules/openstack_project/templates/review.projects.yaml.erb``
and add a new section for your project at the end of the file. It should
look something like::

  - project: stackforge/project-name
    description: Latest and greatest cloud stuff.
    upstream: git://github.com/awesumsauce/project-name.git

The description will set the project description on the GitHub
StackForge mirror, and the upstream should point at an existing
repository which can be used to preseed Gerrit with an initial commit
history. Both of these are optional. Note that the current tools
assume that the upstream repo will have a master branch.

The next step is to add a Gerrit ACL config file. Edit
``openstack-infra/config/modules/openstack_project/files/gerrit/acls/stackforge/project-name.config``
and make it look like::

  [access "refs/heads/*"]
          label-Code-Review = -2..+2 group project-name-core
          label-Approved = +0..+1 group project-name-core
          workInProgress = group project-name-core
  [access "refs/tags/*"]
          create = group project-name-core
          pushTag = group project-name-core
  [receive]
          requireChangeId = true
          requireContributorAgreement = true
  [submit]
          mergeContent = true

The access sections in the example ACL grant the project's core group
approval privileges and the ability so set/un-set WIP status on
changes, as well as the ability to push tags. The other sections set
some required options for Gerrit to function normally (enforcing
presence of a Change-Id in commits and allowing changes to be merged).
This example also expects contributors to agree to a standard
OpenStack CLA, join the OpenStack Foundation and submit contact
information (this feature can be disabled by setting
requireContributorAgreement to false).

That is all that is necessary to add a StackForge project to Gerrit;
however, this project isn't very useful until we setup Jenkins jobs for
it and configure Zuul to run those jobs. Continue reading to configure
these additional tools.

Add Jenkins Jobs to StackForge Projects
=======================================

In the same openstack-infra/config repository (and in the same change
if you like) we need to edit additional files to setup Jenkins jobs
and Zuul for the new StackForge project.

If you are interested in using the standard python Jenkins jobs (docs,
pep8, python 2.6 and 2.7 unittests, and coverage), edit
``openstack-infra/config/modules/openstack_project/files/jenkins_job_builder/config/projects.yaml``
and add a new section for your project at the end of the file. It
should look something like::

  - project:
      name: project-name
      github-org: stackforge
      node: quantal
      tarball-site: tarballs.openstack.org

      jobs:
        - python-jobs

If you aren't ready to run any gate tests yet, you don't need to edit
``projects.yaml``.

Now that we have Jenkins jobs we need to tell Zuul to run them when
appropriate. Edit
``openstack-infra/config/modules/openstack_project/files/zuul/layout.yaml``
and add a new section for your project at the end of the file. It
should look something like::

  - name: stackforge/project-name
    check:
      - gate-project-name-docs
      - gate-project-name-pep8
      - gate-project-name-python26
      - gate-project-name-python27
    gate:
      - gate-project-name-docs
      - gate-project-name-pep8
      - gate-project-name-python26
      - gate-project-name-python27
    post:
      - project-name-coverage
      - project-name-docs
    publish:
      - project-name-docs

If you aren't ready to run any gate tests yet and did not configure
python-jobs in project.yaml, it should look like this instead::

  - name: stackforge/project-name
    check:
      - gate-noop
    gate:
      - gate-noop

That concludes the bare minimum openstack-infra/config changes necessary to
add a project to StackForge. You can commit these changes and submit
them to review.openstack.org at this point, or you can wait a little
longer and add your project to GerritBot first.

Configure StackForge Project to use GerritBot
=============================================

To have GerritBot send Gerrit events for your project to a Freenode IRC
channel edit
``openstack-infra/config/modules/gerritbot/files/gerritbot_channel_config.yaml``.
If you want to configure GerritBot to leave alerts in a channel
GerritBot has always joined just add your project to the project list
for that channel::

  stackforge-dev:
      events:
        - patchset-created
        - change-merged
        - x-vrif-minus-2
      projects:
        - stackforge/libra
        - stackforge/python-reddwarfclient
        - stackforge/reddwarf
        - stackforge/project-name
      branches:
        - master

If you want to join GerritBot to a new channel add a new section to the
end of this file that looks like::

  project-name-dev:
      events:
        - patchset-created
        - change-merged
        - x-vrif-minus-2
      projects:
        - stackforge/project-name
      branches:
        - master

And thats it. At this point you will want to submit these edits as a
change to review.openstack.org.

Add .gitreview file to project
==============================

If the new project you have added has a specified upstream you will need
to add a ``.gitreview`` file to the project once it has been created. This
new file will allow you to use ``git review``.

The basic process is clone from stackforge, add file, push to Gerrit,
review and approve.::

  git clone https://github.com/stackforge/project-name
  cd project-name
  git checkout -b add-gitreview
  cat > .gitreview <<EOF
  [gerrit]
  host=review.openstack.org
  port=29418
  project=stackforge/project-name.git
  EOF
  git review -s
  git add .gitreview
  git commit -m 'Add .gitreview file.'
  git review
