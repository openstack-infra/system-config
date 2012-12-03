:title: StackForge

StackForge
##########

StackForge is the way that OpenStack related projects can consume and
make use of the OpenStack project infrastructure. This includes Gerrit
code review, Jenkins continuous integration, GitHub repository
mirroring, and various small things like IRC bots. Projects should make
use of StackForge if they want to run their project with Gerrit code
review and have a trunk gated by Jenkins.

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

Adding a Project to StackForge
******************************

Create Core Group in Launchpad
==============================

StackForge uses Launchpad for group management. The first step in
creating a StackForge project is to create a team on Launchpad called
``your-project-name-core``. Members of this team will have permissions
to approve code changes to your project.

You can create launchpad teams at https://launchpad.net/people/+newteam.

Creating a new StackForge Project with Puppet
=============================================

OpenStack uses Puppet and a management script to create Gerrit projects
with simple changes to the openstack-ci-puppet repository. To start make
sure you have cloned the openstack-ci-puppet repository
``git clone https://github.com/openstack/openstack-ci-puppet``.

First you need to add your StackForge project to the master project
list. Edit
``openstack-ci-puppet/modules/openstack_project/templates/review.projects.yaml.erb``
and add a new section for your project at the end of the file. It should
look something like::

  - project: stackforge/project-name
    description: Latest and greatest cloud stuff.
    acl_config: /home/gerrit2/acls/stackforge/project-name.config
    upstream: git://github.com/awesumsauce/project-name.git

The description will set the project description on the GitHub
StackForge mirror, and the upstream should point at an existing
repository that should be used to preseed Gerrit. Both of these options
are optional, but you must have an acl_config.

The next step is to add a Gerrit ACL config file. Edit
``openstack-ci-puppet/modules/openstack_project/files/gerrit/acls/stackforge/project-name.config``
and make it look like::

  [access "refs/heads/*"]
          label-Code-Review = -2..+2 group project-name-core
          label-Approved = +0..+1 group project-name-core
          workInProgress = group project-name-core
  [project]
          state = active
  [receive]
          requireChangeId = true
          requireContributorAgreement = true
  [submit]
          mergeContent = true

That is all that is necessary to add a StackForge project to Gerrit;
however, this project isn't very useful until we setup Jenkins jobs for
it and configure Zuul to run those jobs. Continue reading to configure
these additional tools.

Adding Jenkins Jobs to StackForge Projects
==========================================

In the same openstack-ci-puppet repository (and in the same change if
you like) we need to edit two additional files to setup Jenkins jobs
and Zuul for the new StackForge project.

Edit
``/openstack-ci-puppet/modules/openstack_project/files/jenkins_job_builder/config/projects.yaml``
and add a new section for your project at the end of the file. It should
look something like::

  - project:
      name: project-name
      github-org: stackforge
      node: precise

      jobs:
        - gate-{name}-merge

This will add a single Jenkins job for your project called
gate-project-name-merge. This job will return success if the submitted
change can be merged into the current state of your project's master
branch and failure otherwise. Additional tests are possible but this is
the bare minumum needed..

Now that we have a Jenkins job we need to tell Zuul to run that job when
appropriate. Edit
``/openstack-ci-puppet/modules/openstack_project/files/zuul/layout.yaml``
and add a new section for your project at the end of the file. It should
look something like::

  - name: stackforge/project-name
    check:
      - gate-project-name-merge
    gate:
      - gate-project-name-merge

This configures zuul to check if change patchsets can merge on every
submission to Gerrit and will check that the change can merge before
attempting to merge approved changes.

That concludes the bare minimum openstack-ci-puppet changes necessary to
add a project to StackForge. You can commit these changes and submit
them to review.openstack.org at this point, or you can wait a little
longer and add your project to GerritBot first.

Configure StackForge Project to use GerritBot
=============================================

To have GerritBot send Gerrit events for your project to a Freenode IRC
channel edit
``openstack-ci-puppet/modules/gerritbot/files/gerritbot_channel_config.yaml``.
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
