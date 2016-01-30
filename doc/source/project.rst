:title: Infrastructure Project

.. _infra-project:

Infrastructure Project
######################

The infrastructure for the OpenStack project itself is run with the
same processes, tools and philosophy as any other OpenStack project.
The infrastructure team is an open meritocracy that welcomes new
members.  You can read about the OpenStack way on the wiki:

* https://wiki.openstack.org/wiki/How_To_Contribute
* https://wiki.openstack.org/wiki/Open
* https://wiki.openstack.org/wiki/Governance
* https://wiki.openstack.org/wiki/Programs

Scope
=====

The project infrastructure encompasses all of the systems that are
used in the day to day operation of the OpenStack project as a whole.
This includes development, testing, and collaboration tools.  All of
the software that we run is open source, and its configuration is
public.  The project still uses a number of systems that do not yet
fall under this umbrella (notably, the main website), but we're
working to incorporate them so that people may just as easily
contribute to those areas.  All new services used by the project
should begin as part of the infrastructure project to ensure easy
collaboration from the start.

Contributing
============

We welcome contributions from new contributors.  Reading this
documentation is the first step.  You should also join our `mailing list <http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-infra>`_.

We are most active on IRC, so please join the **#openstack-infra**
channel on Freenode.

Feel free to attend our `weekly IRC meeting
<https://wiki.openstack.org/wiki/Meetings/InfraTeamMeeting>`_.
on Tuesdays at 19:00 UTC in #openstack-meeting.

Check out our open bugs on `StoryBoard
<https://storyboard.openstack.org/#!/project_group/55>`_.

We hold regular `bug days
<https://wiki.openstack.org/wiki/InfraTeam#Bugs>`_ where we review and
triage bugs.

To read about how our systems are managed and how to view or edit
those configurations, see :ref:`sysadmin`.

We also have a collection of `OpenStack Project Infrastructure Publications
<http://docs.openstack.org/infra/publications/>`_ where we host slides for
presentations team members have given about the infrastructure.

And if you have any questions, please ask.

Bugs
====

The infrastructure project maintains a bug list at:

  https://storyboard.openstack.org/#!/project_group/55

Both defects and new features are tracked in the bug system.  A number
of tags are used to indicate relevance to a particular subsystem.
There is also a low-hanging-fruit tag associated with bugs that should
provide a gentle introduction to working on the infrastructure project
without needing too much in-depth knowledge or access.

Priority Efforts
================

The infrastructure project designates a small number of efforts
underway at any time as priority efforts.  These are areas where the
project has decided to focus resources to achieve major initiatives.
These help reviewers prioritize their review workload and help to
ensure the project accomplishes important tasks.  Priority efforts are
a great way to get involved in the project as they will generally
provide the most interaction with experienced contributors.

Priority efforts are documented in the infra-specs repo.  Each
priority effort has one entry in infra-specs, though that may link to
multiple smaller specifications for individual units of work if the
effort is sufficiently large.  Each priority effort also has a single
person designated as the driver of that effort.  That person is
responsible for ensuring that anything blocking progress of the effort
is discussed at team meetings and may be a good point of contact for
someone who wants to get involved.

Changes not related to priority efforts will be reviewed by the core
review team as time permits.  This may mean that they spend
considerable time in review, but they will be reviewed eventually.  If
a change is urgent, you might consider contacting someone in
#openstack-infra on Freenode.

Teams
=====

The infrastructure project is open, meaning anyone may join and begin
contributing with no formal process.  As an individual's contributions
and involvement grow, there are more formal roles.  These roles are
designed to empower groups of people to get work done in their area of
expertise and interest, as well as supply a strong sense of direction
for the infrastructure project as a whole.  Everyone participating in
the project is encouraged to expand their own knowledge while helping
to support and mentor others as they progress.

Core Teams
  The infrastructure project is composed of a large number of
  subprojects.  Every source code repository has its own core team
  which is responsible for maintenance of that subproject, with some
  groups of repositories sharing a core team.  These core teams are
  empowered to approve changes that reflect the currently understood
  project direction.  Changes in project direction or major new
  initiatives must be approved by the infrastructure council.

  Any existing core team member may nominate someone for addition to
  that core team by private communication with the infrastructure PTL.
  The PTL will consider the opinions of the existing core team members
  and the review history of the person in question, but final
  determination of core team membership (additions and removals) rests
  with the PTL.  This process is private to enable honest evaluations
  in a safe environment.

Infrastructure Core Team
  Individuals who show an interest in a wide range of areas of the
  infrastructure project may be asked to join the infra-core team.  To
  provide a baseline level of support to all of our subprojects and to
  ensure that important efforts may move forward, this team has
  approval rights in all infrastructure repositories.  Members of this
  team may not be experts in all areas, but know their limits, and
  will not exceed those limits when reviewing changes outside of their
  area of expertise.

  They are expected to have a wide general knowledge of what is going
  on in the infrastructure project and to help guide overall project
  direction.  To that end, they are able to veto specs proposed to the
  infrastructure council.

Infrastructure Council
  The infrastructure council is the technical design body for the
  infrastructure project.  While individuals and groups are empowered
  to execute the designs from the concil, major technical designs are
  agreed upon as a group to ensure that our large set of projects are
  all working together to the same end.  The council need not delve
  too deeply into technical detail -- just enough so that development
  efforts may happen in parallel and work toward a common goal.

  All members of any infrastructure project core team have a seat on
  the Council.  The Council is responsible for approving changes in
  project direction, major new initiatives, setting priority efforts,
  and addition or removal of projects.

  Any such changes should be proposed to the infra-specs repository.
  Anyone is welcome to review specs and they are expected to evolve
  during the review process.  When a change to infra-specs is ready
  for final approval, the author will add the change to the infra team
  meeting agenda so that the entire team is notified that the spec is
  ready.  Members of the council will vote by leaving reviews on the
  spec to approve or reject the change.  The determination will be
  based on a majority vote, with members of the infra-core team able
  to veto, and in the case of a tie, the PTL will cast the deciding
  vote.  The PTL will execute the workflow action on the change after
  the vote.

  Specs are living documents, and once approved, should be maintained
  for the duration of the effort they describe.  Substantial changes
  in direction should go through the same process described above.
  The PTL may chose to approve insubstantial changes without the
  formal council voting process.

Infrastructure Root Team
  While core membership is analogous to the same system in other
  OpenStack projects, because the infrastructure team operates
  production servers there is another sub-group of the infrastructure
  team that has root access to all servers.  Root membership is
  handled in the same way as core membership.  Root members must also
  be infra-core members, but infra-core members may not necessarily be
  root members.  This is because primary system administration is
  performed through code review, so anyone able to log into a machine
  to execute commands must be able to approve those same commands in
  configuration management; otherwise it would be easier for a person
  to bypass puppet than use it in the intended fashion.

  Root access is generally only necessary to launch new servers,
  perform low-level maintenance, manage DNS, or fix problems.  In
  general it is not needed for day-to-day system administration and
  configuration which is done in puppet (where anyone may propose
  changes).  Therefore it is generally reserved for people who are
  well versed in infrastructure operations and can commit to spending
  a significant amount of time troubleshooting on servers.

  Some individuals may need root access to individual servers; in
  these cases the infra-core group may grant root access on a limited
  basis.

Review Criteria
===============

We review each others changes before they are merged.  This helps us
improve the quality of the code we produce as well as ensure that we
are working together as a team.  Generally we expect at least two
members of the core review team to approve a change before it is
merged, but we are flexible in this requirement -- typo fixes, or
other simple changes may be approved with less formality.

The primary purpose of change review is to catch substantial errors
before they are merged.  In order to keep this process useful and
avoid frustration for both authors and reviewers, please do not leave
negative reviews for insubstantial faults or potential improvements.
The purpose is not to make someone else's code match your vision of
perfection, but to enable all of us to work together on a project.

Please use discretion when deciding what is important enough for
someone to spend the time to rework and for you to spend the time
re-reviewing.  Sometimes minor things are important, such as
consistent use of hyphens versus underscores in a configuration
language.  Sometimes they are not, such as whitespace in
documentation.

If you would like to mention minor improvements such as this, feel
free to do so, but please do not leave a negative score on the review.
If you mention them along with other more substantial criticisms,
please note them in a review, for example, with "(nit)" or "(not a
-1)" or "you may want to fix this if you are updating the patch
anyway".

Please also see the section in the Infrastructure Manual on `peer review
<http://docs.openstack.org/infra/manual/developers.html#peer-review>`_.
