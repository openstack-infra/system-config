:title: Infrastructure Project

Infrastructure Project
######################

The infrastructure for the OpenStack project itself is run with the
same processes, tools and philosophy as any other OpenStack project.
The infrastructure team is an open meritocracy that welcomes new
members.  You can read about the OpenStack way on the wiki:

* https://wiki.openstack.org/wiki/How_To_Contribute
* https://wiki.openstack.org/wiki/Open
* https://wiki.openstack.org/wiki/Governance
* https://wiki.openstack.org/wiki/Teams

Scope
*****

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
************

We welcome contributions from new contributors.  Reading this
documentation is the first step.  You should also join our `mailing list <http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-infra>`_.

We are most active on IRC, so please join the **#openstack-infra**
channel on Freenode.

Check out our open bugs, particularly the `low-hanging-fruit
<https://bugs.launchpad.net/openstack-ci/+bugs?field.tag=low-hanging-fruit>`_,
which are smaller (but still important!) tasks that may not require a
great deal of in-depth knowledge.

Feel free to attend our `weekly IRC meeting
<https://wiki.openstack.org/wiki/Meetings/InfraTeamMeeting>`_.

And if you have any questions, please ask.

Team
****

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

.. _sysadmin:

System Administration
*********************

Our infrastructure is code and contributions to it are handled just
like the rest of OpenStack.  This means that anyone can contribute to
the installation and long-running maintenance of systems without shell
access, and anyone who is interested can provide feedback and
collaborate on code reviews.

The configuration of every system operated by the infrastructure team
is managed by Puppet in a single Git repository:

  https://github.com/openstack-infra/config

All system configuration should be encoded in that repository so that
anyone may propose a change in the running configuration to Gerrit.

Making a Change in Puppet
=========================

Many changes to the Puppet configuration can safely be made while only
performing syntax checks.  Some more complicated changes merit local
testing and an interactive development cycle.  The config repo is
structured to facilitate local testing before proposing a change for
review.  This is accomplished by separating the puppet configuration
into several layers with increasing specificity about site
configuration higher in the stack.

The `modules/` directory holds puppet modules that abstractly describe
the configuration of a service.  Ideally, these should have no
OpenStack-specific information in them, and eventually they should all
become modules that are directly consumed from PuppetForge, only
existing in the config repo during an initial incubation period.  This
is not yet the case, so you may find OpenStack-specific configuration
in these modules, though we are working to reduce it.

The `modules/openstack_project/manifests/` directory holds
configuration for each of the servers that the OpenStack project runs.
Think of these manifests as describing how OpenStack runs a particular
service.  However, no site-specific configuration such as hostnames or
credentials should be included in these files.  This is what lets you
easily test an OpenStack project manifest on your own server.

Finally, the `manifests/site.pp` file contains the information that is
specific to the actual servers that OpenStack runs.  These should be
very simple node definitions that largely exist simply to provide
private date from hiera to the more robust manifests in the
`openstack_project` modules.

This means that you can run the same configuration on your own server
simply by providing a different manifest file instead of site.pp.

As an example, to run the etherpad configuration on your own server,
start by cloning the config Git repo::

  git clone https://github.com/openstack-infra/config

Then copy the etherpad node definition from manifests/site.pp to a new
file (be sure to specify the FQDN of the host you are working with in
the node specifier).  It might look something like this::

  # local.pp
  node 'etherpad.example.org' {
    class { 'openstack_project::etherpad':
      database_password       => 'badpassword',
      sysadmins               => 'user@example.org',
    }
  }

Then to apply that configuration, run the following::

  cd config
  bash install_puppet.sh
  bash install_modules.sh
  puppet apply -l manifest.log --modulepath=modules:/etc/puppet/modules local.pp

That should turn the system you are logged into into an etherpad
server with the same configuration as that used by the OpenStack
project.  You can edit the contents of the config repo and iterate as
needed.  When you're ready to propose the change for review, you can
propose the change with git-review.  See the `Gerrit Workflow wiki
article <https://wiki.openstack.org/wiki/GerritWorkflow>`_ for more
information.

Bugs
****

The infrastructure project maintains a bug list at:

  https://bugs.launchpad.net/openstack-ci

Both defects and new features are tracked in the bug system.  A number
of tags are used to indicate relevance to a particular subsystem.
There is also a low-hanging-fruit tag associated with bugs that should
provide a gentle introduction to working on the infrastructure project
without needing too much in-depth knowledge or access.
