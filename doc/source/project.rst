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

Team
====

The infrastructure team is open, meaning anyone may join and begin
contributing with no formal process.  As an individual's contributions
and involvement grow, there are more formal roles in the team:

Core Members
  Core team members are able to approve or reject proposed changes to
  any of the infrastructure projects.  If an individual shows
  commitment and aptitude in code reviews, the current core team
  membership will take notice and propose that person for inclusion in
  the core team, and hold a vote to make the final determination.

  In addition to the project-wide infrastructure group, individual
  infrastructure projects (such as Jenkins Job Builder or Reviewday)
  may also have their own core teams as necessary.

Root Members
  While core membership is directly analogous to the same system in
  other OpenStack projects, because the infrastructure team operates
  production servers, there is another sub-group of the infrastructure
  team that has root access to all servers.  Root membership is
  handled in the same way as core membership.  Root members must also
  be core members, but core members may not necessarily be root
  members.

  Root access is generally only necessary to launch new servers,
  perform low-level maintenance, manage DNS, or fix problems.  In
  general it is not needed for day-to-day system administration and
  configuration which is done in puppet (where anyone may propose
  changes).  Therefore it is generally reserved for people who are
  well versed in infrastructure operations and can commit to spending
  a significant amount of time troubleshooting on servers.

  Some individuals may need root access to individual servers; in
  these cases the core group may grant root access on a limited basis.

Bugs
====

The infrastructure project maintains a bug list at:

  https://storyboard.openstack.org/#!/project_group/55

Both defects and new features are tracked in the bug system.  A number
of tags are used to indicate relevance to a particular subsystem.
There is also a low-hanging-fruit tag associated with bugs that should
provide a gentle introduction to working on the infrastructure project
without needing too much in-depth knowledge or access.

