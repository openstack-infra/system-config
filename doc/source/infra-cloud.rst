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
expanded capacity for the OpenStack infrastructure nodepool.

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
24 Cores of Intel Xeon X5650 @ 2.67GHz processors. Externally routable
addresses are only avaialable on 802.1Q vlan 25. See "Vlans" below.

HP2
~~~

The HP2 site has 100 machines. Each machine has 96G of RAM, 1.8TiB of disk and
32 Cores of Intel Xeon E5-2670 0 @ 2.60GHz processors. Externally routable
addresses are only avaialable on 802.1Q vlan 25. See "Vlans" below.

Vlans
~~~~~

In sites which have an untagged internal network, and a tagged external
network, like `HP1` and `HP2`, we won't be able to reach in and configure
things via SSH from an external site until the routable vlan is setup. The
most future-proof way to do this would be to support the spec that adds
vlan information to config-drive. [vlan-config-drive]_

Since we are using `Bifrost`, we can use that spec even though Nova and
Neutron are still debating how and when to inject that information into
configdrive. We can simply do that in bifrost. This will require some
minor patches to `Bifrost`, or we can even add our own playbooks that
operate on the nodes after enrolling to add this info.

This will also require patches to `glean` to pull the vlan information
out and configure interfaces accordingly.

.. [vlan-config-drive] http://specs.openstack.org/openstack/nova-specs/specs/liberty/approved/metadata-service-network-info.html

Software
--------

Infra-cloud runs the most recent OpenStack stable release. During the
period following a release, plans must be made to upgrade as soon as
possible. In the future the cloud may be continuously deployed.

Management
----------

 * A "Ironic Controller" machine is installed by hand into each site. That
   machine is enrolled into the puppet/ansible infrastructure.

 * The "Ironic Controller" will have bifrost installed on it. All of the
   other machines in that site will be enrolled in the Ironic that bifrost
   manages. bifrost will be responsible for booting base OS with IP address
   and ssh key for each machine.

 * The machines will all be added to a manual ansible inventory file adjacent
   to the dynamic inventory that ansible currently uses to run puppet. Any
   metadata that the ansible infrastructure for running puppet needs that
   would have come from OpenStack infrastructure will simply be put into
   static ansible group_vars.

 * The static inventory should be put into puppet so that it is public, with
   the IPMI passwords in hiera.

 * An OpenStack Cloud with KVM as the hypervisor will be installed using
   OpenStack puppet modules as per normal infra installation of services.

 * As with all OpenStack services, metrics will be collected in public
   cacti and graphite services. The particular metrics are TBD.

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

  * The cloud will use KVM because it is the default free hypervisor and
    has the widest user base in OpenStack.

  * The cloud will use Neutron configured for Provider VLAN because we
    do not require tenant isolation and this simplifies our networking on
    compute nodes.

  * The cloud will not use floating IPs because every node will need to be
    reachable via routable IPs and thus there is no need for separation. Also
    Nodepool is under our control, so we don't have to worry about DNS TTLs
    or anything else causing a need for a particular endpoint to remain at
    a stable IP.

  * The cloud will not use security groups because these are single use VMs
    and they will configure any firewall inside the VM.

  * The cloud will use MySQL because it is the default in OpenStack and has
    the widest user base.

  * The cloud will use RabbitMQ because it is the default in OpenStack and
    has the widest user base. We don't have scaling demands that come close
    to pushing the limits of RabbitMQ.

  * The cloud will run swift as a backend for glance so that we can scale
    image storage out as need arises.

  * The cloud will run keystone v3 and glance v2 APIs because these are the
    versions upstream recommends using.

  * The cloud will not use the glance task API for image uploads, it will use
    the PUT interface because the task API does not function and we are not
    expecting a wide user base to be uploading many images simultaneously.

  * The cloud will provide DHCP directly to its nodes because we trust DHCP.

  * The cloud will have config drive enabled because we believe it to be more
    robust than the EC2-style metadata service.

  * The cloud will not have the meta-data service enabled because we do not
    believe it to be robust.

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
nodes. Whether we use LinuxBridge or Open vSwitch is still TBD.
