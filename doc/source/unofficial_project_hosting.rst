:title: Unofficial Projects

.. _unofficial-projects:

Unofficial Project Hosting
##########################

Unofficial project hosting is the way that OpenStack related projects can
consume and make use of the OpenStack project infrastructure. This
includes Gerrit code review, Zuul continuous integration, GitHub
repository mirroring, and various small things like IRC bots, pypi uploads,
RTFD updates. Projects should make use of being an unofficial project if
they want to run their project with Gerrit code review and have a trunk
gated by Zuul.

Unofficial projects are expected to be self sufficient when it comes to
configuring Gerrit/Zuul etc. The openstack-infra team can provide
assistance as resources allow, but should not be relied on.

What being an unoffocial project is not:

* Official endorsement of a project by OpenStack.
* A guarantee of eventual inclusion as an official OpenStack project
  (though it is a good first step in that process as it exposes the project
  to the OpenStack way of doing things and tooling).

Historical Background
*********************

Previously unofficial projects were hosted as part of "Stackforge" which
had its own namespace in Gerrit and Github (stackforge/). It is common
for unofficial projects to become official projects and when that happened
with the old stackforge/ namespace we had to perform Gerrit downtimes to
rename things to use the openstack/ namespace. In response to this we
collapsed the stackforge/ namespace into the openstack/ namespace. This
means both unofficial projects and official projects are hosted under the
openstack/ namespace in Gerrit and Github. This means that not all
projects under openstack/ are official OpenStack projects they are instead
simply hosted by the OpenStack project infrastructure.

Eventually the TC decided to completely deprecate the Stackforge name
though you may still hear it being used as short hand for "Unofficial
Project".

Audience
********

The focus of unofficial project hosting is to provide a place for OpenStack
contributors to maintain related unofficial projects using the same tools
and procedures as they employ when working on official OpenStack projects,
to make it easier for other OpenStack developers to contribute effort to
those projects and in some cases to ease a project's path to incubation
and official integration. As such, the target audience for this document
is current OpenStack developers who are assumed to already be familiar
with how changes are uploaded and reviewed within OpenStack projects. As
an introduction to OpenStack contribution, it is recommend to first read
https://wiki.openstack.org/wiki/How_To_Contribute and then
the `Developer's Guide <http://docs.openstack.org/infra/manual/developers.html>`_.

Create an Unofficial Project
****************************

For information on adding an unofficial project, see the `Project
Creator's Guide
<http://docs.openstack.org/infra/manual/creators.html>`_.
