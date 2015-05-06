:title: Infra Cloud

.. _infra_cloud:

Infra Cloud
###########

Introduction
============

With donated hardware and datacenter space, we can run an optimized
semi-private cloud for the purpose of adding testing capacity and also
with an eye for "dog fooding" OpenStack itself.

Current Status
==============

Currently this cloud is in the planning and design phases. This section
will be updated or removed as that changes.

Mission
=======

The infra-cloud's mission is to turn donated raw hardware resources into
expanded capacity for the purpose of running OpenStack check and gate
tests.

Methodology
===========

Infra-cloud is run like any other infra managed service. Puppet modules
do the bulk of configurating hosts, and Gerrit code review drives 99% of
activities, with logins used only for debugging and repairing the
service.

Requirements
============

 * Compute - The intended workload is mostly nodepool launched jenkins
   slaves.

 * Images - Image upload must be allowed for nodepool.

 * Uptime - infra-cloud must have a reasonable degree of fault tolerance
   and high availability that it will remain up and running tests with a
   fair degree of confidence.

 * Performance - The performance of compute and networking in infra-cloud
   should be at least as good as, if not better than, the other nodepool
   clouds that infra uses today.

 * Infra-core - Infra-core is in charge of running the service.

Implementation
==============

Regions
-------

There are two regions in separate racks and they share nothing except
the infra puppet master.

Software
--------

 * Infra-cloud runs the most recent OpenStack stable release. During the
   period following a release, plans must be made to upgrade as soon as
   possible. In the future the cloud may be contiuously deployed.

Management
----------

 * A Nova+Ironic service is installed on the first node, and all machines are
   enrolled in said Ironic service. Ansible playbooks provision the rest
   of the cloud and enroll the machines into infra's puppet as those
   machines come online.

 * Once machines are booted with the base image, roles are assigned and
   puppet is used to enact the desired configuration.

 * The "PuppetOpenStack" modules available in stackforge will be used to
   deploy and configure OpenStack on the machines.

Architecture
------------

 * The generally accepted "Controller" and "Compute" layout is used,
   with controllers running all non-compute services and compute nodes
   running only nova-compute and supporting services.

     * The cloud is deployed with two controllers in a DRBD storage pair
       with ACTIVE/PASSIVE configured and a VIP shared between the two.
       This is done to avoid complications with Galera and RabbitMQ at
       the cost of making failovers more painful and under-utilizing the
       passive stand-by controller.

 * A minimal swift installation is deployed on the controllers
   to facilitate shared image storage. 

Networking
----------

 * Neutron is used, with a single provider VLAN attached to VMs for the
   simplest possible flat networking. DHCP is configured to hand the
   machine a routable IP which can be reached directly from the internet
   to facilitate nodepool/zuul.
