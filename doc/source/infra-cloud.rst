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

The infra-cloud's mission is to turn donated raw hardware resources
into expanded capacity for the purpose of providing expanded capacity
for the OpenStack infrastructure nodepool.

Methodology
===========

Infra-cloud is run like any other infra managed service. Puppet modules
and Ansible do the bulk of configuring hosts, and Gerrit code review
drives 99% of activities, with logins used only for debugging and
repairing the service.

Requirements
============

 * Compute - The intended workload is mostly nodepool launched Jenkins
   slaves. Thus flavors that are capable of running these tests in a
   reasonable amount of time must be available. The flavor(s) must provide:

    * 8GB RAM

    * 8 * `vcpu`

    * 30GB root disk

 * Images - Image upload must be allowed for nodepool.

 * Uptime - Because there are other clouds that can keep some capacity
   running, 99.9% uptime should be acceptable.

 * Performance - The performance of compute and networking in infra-cloud
   should be at least as good as, if not better than, the other nodepool
   clouds that infra uses today.

 * Infra-core - Infra-core is in charge of running the service.

Implementation
==============

Multi-Site
----------

There are at least two "sites" with a collection of servers in each
site. Each site will have its own cloud, and these clouds will share no
infrastructure or data. The racks may be in the same physical location,
but they will be managed as if they are not.

HP1
~~~

The HP1 site has 48 machines. Each machine has 96G of RAM, 1.8TiB of disk and
24 Cores of Intel Xeon X5650 @ 2.67GHz processors.

HP2
~~~

The HP2 site has 100 machines. Each machine has 96G of RAM, 1.8TiB of disk and
32 Cores of Intel Xeon E5-2670 0 @ 2.60GHz processors.

Software
--------

Infra-cloud runs the most recent OpenStack stable release. During the
period following a release, plans must be made to upgrade as soon as
possible. In the future the cloud may be contiuously deployed.

Management
----------

 * A "Ironic Controller" machine is installed by hand into each site. That
   machine is enrolled into the puppet/ansible infrasturcture.

 * An all-in-one one node OpenStack cloud with Ironic as the Nova driver is
   installed on each Ironic Controller node. The OpenStack Cloud produced
   by this installation will be referred to as "Ironic Cloud $site"

 * Each additional machine in a site will be enrolled into the Ironic Cloud
   as bare metal resources.

 * Each Ironic Cloud $site will be added to the list of available clouds that
   launch_node.py or the ansible replacement for it can use to spin up long
   lived servers.

 * An OpenStack Cloud with KVM as the hypervisor will be installed using
   launch_node and the OpenStack puppet modules as per normal infra
   installation of services.

 * As with all OpenStack services, metrics will be collected in public
   cacti and graphite services.

 * As a cloud has a large amount of pertinent log data, a public ELK cluster
   will be needed to capture and expose it.

 * All Infra services run on the public internet, and the same will be true
   for the Infra Clouds and the Ironic Clouds. Insecure services that need
   to be accessible across machine boundaries will employ per-IP iptables
   rules rather then relying on a squishy middle.

Architecture
------------

The generally accepted "Controller" and "Compute" layout is used,
with controllers running all non-compute services and compute nodes
running only nova-compute and supporting services.

  * The cloud is deployed with two controllers in a DRBD storage pair
    with ACTIVE/PASSIVE configured and a VIP shared between the two.
    This is done to avoid complications with Galera and RabbitMQ at
    the cost of making failovers more painful and under-utilizing the
    passive stand-by controller.

  * The cloud will use KVM

  * The cloud will use Neutron configured for Provider VLAN

  * The cloud will not use floating IPs

  * The cloud will not use security groups

  * The cloud will use MySQL

  * The cloud will use RabbitMQ

  * The cloud will run swift as a backend for glance

  * The cloud will run keystone v3 and glance v2 APIs

  * The cloud will not use the glance task API for image uploads, it will use
    the PUT interface

  * The cloud will not run Horizon, Cinder, Ceilometer, Heat, Trove or Sahara

  * The cloud will provide DHCP directly to its nodes

  * The cloud will have config drive enabled

  * The cloud will not have the meta-data service enbled

Networking
----------

Neutron is used, with a single `provider VLAN`_ attached to VMs for the
simplest possible networking. DHCP is configured to hand the machine a
routable IP which can be reached directly from the internet to facilitate
nodepool/zuul communications.

.. _provider VLAN: http://docs.openstack.org/networking-guide/deploy_scenario4b.html

Each site will need 2 VLANs. One for the public IPs which every NIC of every
host will be attached to. That VLAN will get a publicly routable /23. Also,
there should be a second VLAN that is connected only to the NIC of the
Ironic Cloud and is routed to the IPMI management network of all of the other
nodes.
