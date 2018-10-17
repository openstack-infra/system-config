:title: Contributing Cloud Test Resources

.. _contributing_cloud:

Contributing Cloud Test Resources
#################################

OpenStack utilizes a "project gating" system based on `Zuul
<https://docs.openstack.org/infra/zuul/>`_ to ensure that every change
proposed to any OpenStack project passes tests before being added to
its source code repository.  Each change may run several jobs which
test the change in various configurations, and each job may run
thousands of individual tests.  To ensure the overall security of the
system as well as isolation between unrelated changes, each job is run
on an OpenStack compute instance that is created specifically to run
that job and is destroyed and replaced immediately after completing
that task.

This system operates across multiple OpenStack clouds, making the
OpenStack project infrastructure itself a substantial and very public
cross-cloud OpenStack application.

The compute instances used by this system are generously donated by
organizations that are contributing to OpenStack, and the project is
very appreciative of this.

By visiting https://zuul.openstack.org/ you can see the system in
action at any time.

You'll see every job that's running currently, as well as some graphs
that show activity over time.  Each of those jobs is running on its
own compute instance.  We create and destroy quite a number of those
each day (most compute instances last for about 1 hour).

Having resources from more providers will help us continue to grow the
project and deliver test results to developers quickly.  OpenStack has
long-since become too complicated for developers to effectively test in
even the most common configurations on their own, so this process is
very important for developers.

If you have some capacity on an OpenStack cloud that you are able to
contribute to the project, it would be a big help.  This is what we
need:

* Nova and Glance APIs (with the ability to upload images)
* A single instance with 500GB of disk (via Cinder is preferred, local
  is okay) per cloud region for our region-local mirror

Each test instance requires:

* 8GB RAM
* 8vCPU at 2.4GHz (or more or less vCPUs depending on speed)
* A public IP address (IPv4 and/or IPv6)
* 80GB of storage

In a setting where our instances will be segregated, our usage
patterns will cause us to be our own noisy neighbors at the worst
times, so it would be best to plan for little or no overcommitment.
In an unsegregrated public cloud setting, the distribution of our jobs
over a larger number of hypervisors will allow for more
overcommitment.

Since there's a bit of setup and maintenance involved in adding a new
provider, a minimum of 100 instances would be helpful.

Benefits to Contributors
========================

Since we continuously use the OpenStack APIs and are familiar with how
they should operate, we occasionally discover potential problems with
contributing clouds before many of their other users (or occasionally
even ops teams).  In these cases, we work with contacts on their
operations teams to let them know and try to help fix problems before
they become an issue for their customers.

We collect numerous metrics about the performance of the clouds we
utilize. From these metrics we create dashboards which are freely
accessible via the Internet to help providers see and debug
performance issues.

The names and regions of providers are a primary component of
hostnames on job workers, and as such are noticeable to those
reviewing job logs from our CI system (as an example, developers
investigating test results on proposed source code changes). In this
way, names of providers contributing test resources become known to
the technical community in their day-to-day interaction with our
systems.

The OpenStack Foundation has identified Infrastructure Donors as a
special category of sponsoring organization and prominently identifies
those contributing a significant quantity of resources (as determined
by the Infra team) at:
https://www.openstack.org/foundation/companies/#infra-donors

If this sounds interesting, and you have some capacity to spare, it
would be very much appreciated.  You are welcome to contact the
Infrastructure team on our public mailing list at
<openstack-infra@lists.openstack.org>, or in our IRC channel,
`#openstack-infra` on Freenode.  You are also welcome to privately
contact the `Infrastructure Project Team lead
<https://governance.openstack.org/tc/reference/projects/infrastructure.html>`_.

Contribution Workflow
=====================

After discussing your welcome contribution with the infrastructure
team it will be time to build and configure the cloud.

Initial setup
-------------

We require two projects to be provisioned

* A ``zuul`` project for infrastructure testing nodes
* A ``ci`` project for control-plane services

The ``zuul`` project will be used by nodepool for running the testing
nodes.  Note there many be references in configuration to projects
with ``jenkins``; although this is not used any more some original
clouds named thier projects for the CI system in use at the time.

The ``ci`` project has at a minimum the region-local mirror host(s)
for the cloud's region(s).  This will be named
``mirror.<region>.<cloud>.openstack.org`` and all jobs running in the
``zuul`` project will be configured to use it as much as possible
(this might influence choices you make in network setup, etc.).
Depending on the resources available and with prior co-ordination with
the provider, the infrastructure team may also run other services in
this project such as webservers, file servers or nodepool builders.

The exact project and user names is not particularly important,
usually something like ``openstack[ci|zuul]`` is chosen.  Per below,
these will exist as ``openstackci-<provider>``
``openstackzuul-<provider>`` in various ``clouds.yaml`` configuration
files.  For minimising potential for problems it is probably best that
the provided users do not have "admin" credentials; although in some
clouds that are private to OpenStack infra we may have admin
permissions, or have available a user with such permissions to help
with various self-service troubleshooting.  For example, the
infrastructure team does not require any particular access to subnet
or router configuration in the cloud, although where requested we are
happy to help with this level of configuration.

Add cloud configuration
-----------------------

After creating the two projects and users, configuration and
authentication details need to be added into configuration management.
The public portions can be proposed via the standard review process at
any time by anyone.  Exact details of cloud configuration changes from
time to time; the best way to begin the addition is to clone the
``system-configuration`` repository (i.e. this repo) with ``git clone
git://git.openstack.org/openstack-infra/system-config`` and ``grep``
for an existing cloud (or go through ``git log`` and find the last
cloud added) and follow the pattern.  After posting the review, CI
tests and reviewers will help with any issues.

These details largely consist of the public portions of the
``openstackclient`` configuration format, such as the endpoint and
version details.  Note we require ``https`` communication to Keystone;
we can use self-signed certificates if required, some non-commercial
clouds use `letsencrypt <https://letsencrypt.org>`__ while others use
their CA of preference.

Once the public review is ready, the secret values used in the review
need to be manually entered by an ``infra-root`` member into the
secret storage on ``bridge.openstack.org``.  You can communicate these
via GPG encrypted mail to a ``infra-root`` member (ping ``infra-root``
in ``#openstack-infra`` and someone will appear).  If not told
explicitly, most sign the OpenStack signing key, so you can find their
preferred key via that; if the passwords can be changed plain-text is
also fine.  With those in place, the public review will be committed
and the cloud will become active.

Once active, ``bridge.openstack.org`` will begin regularly running
`ansible-role-cloud-launcher
<http://git.openstack.org/cgit/openstack/ansible-role-cloud-launcher/>`__
against the new cloud to configure keys, upload base images, setup
security groups and such.

Activate in nodepool
--------------------

After the cloud is configured, it can be added as a resource for
nodepool to use for testing nodes.

Firstly, an ``infra-root`` member will need to make the region-local
mirror server, configure any required storage for it and setup DNS
(see :ref:`adding_new_server`).  With this active, the cloud is ready
to start running testing nodes.

At this point, the cloud needs to be added to nodepool configuration
in `project-config
<https://git.openstack.org/cgit/openstack-infra/project-config/tree/nodepool>`__.
Again existing entries provide useful templates for the initial review
proposal, which can be done by anyone.  Some clouds provision
particular flavors for CI nodes; these need to be present at this
point and will be conveyed via the nodepool configuration.  Again CI
checks and reviewers will help with any fine details.

Once this is committed, nodepool will upload images into the new
region and start running nodes automatically.  Don't forget add the
region to the `grafana
<https://git.openstack.org/cgit/openstack-infra/project-config/tree/grafana>`__
configuration to ensure we have a dashboard for the region's health.
