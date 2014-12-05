:title: StackForge

.. _stackforge:

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

Audience
********

The focus of StackForge is to provide a place for OpenStack contributors
to maintain related unofficial projects using the same tools and
procedures as they employ when working on official OpenStack projects,
to make it easier for other OpenStack developers to contribute effort to
those projects and in some cases to ease a project's path to incubation
and official integration. As such, the target audience for this document
is current OpenStack developers who are assumed to already be familiar
with how changes are uploaded and reviewed within OpenStack projects. As
an introduction to OpenStack contribution, it is recommend to first read
https://wiki.openstack.org/wiki/How_To_Contribute and then
the `Developer's Guide <http://docs.openstack.org/infra/manual/developers.html>`_.

Add a Project to StackForge
***************************

For information on adding a project to StackForge, see the `Project
Creator's Guide
<http://docs.openstack.org/infra/manual/creators.html>`_.
