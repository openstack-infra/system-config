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

Single datacenter
-----------------

Our servers are placed on a single datacenter (HPE Houston Ecopod), on different
racks. The servers are composed by three different types of hardware:
- HP Proliant SL230Gen8
- HP Proliant SE1170s
- HP Proliant SL390s

SL390 machines come with 96G of RAM, 1.8TiB of disk and 24 Cores of Intel Xeon X5650 @ 2.67GHz processors.
SL230 adn SE1170 machines come with 96G of RAM, 1.8TiB of disk and 32 Cores of Intel Xeon E5-2670 0 @ 2.60GHz processors.

Rack distribution
-----------------

Our servers are distributed on different racks, each of those containing different
sets of hardware:

Rack 5
~~~~~~

24 x SL230
16 x SE1170

Rack 8
~~~~~~

16 x SE1170

Rack 9
~~~~~~

20 x SE1170

Rack 12
~~~~~~~
23 x SL390
13 X SL230
4  X SE1170

Rack 13
~~~~~~~

8 x SL390
8 x SE1170

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

  * The cloud will run keystone on port 443.

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

.. _provider VLAN: http://docs.openstack.org/networking-guide/scenario-provider-lb.html

Each site will need 2 VLANs. One for the public IPs which every NIC of every
host will be attached to. That VLAN will get a publicly routable /19. Also,
there should be a second VLAN that is connected only to the NIC of the
Ironic Cloud and is routed to the IPMI management network of all of the other
nodes. We will be using LinuxBridge at first deployments.

Following ranges are used:

  * OSCI iLO: 10.12.8.0/22 (VLAN 1807)
  * OSCI MGMT: 10.10.16.0/22 (VLAN 2550)
  * OSCI Public: 15.184.224.0/19 (VLAN 2551)

Troubleshooting
===============

Regenerating images
-------------------

When redeploying servers with bifrost, we may have the need to refresh the image
that is deployed to them, because we may need to add some packages, update the
elements that we use, consume latest versions of projects...

To generate an image, you need to follow these steps::

  1. In the baremetal server, remove everything under /httpboot directory.
     This will clean the generated qcow2 image that is consumed by servers.

  2. If there is a need to also update the CoreOS image, remove everything
     under /tftpboot directory. This will clean the ramdisk image that is
     used when PXE booting.

  3. Run the install playbook again, so it generates the image. You need to
     be sure that you pass the skip_install flag, to avoid the update of all
     the bifrost related projects (ironic, dib, etc...):

     ansible-playbook -vvv -e @/etc/bifrost/bifrost_global_vars \
         -e skip_install=true \
         -i /opt/stack/bifrost/playbooks/inventory/bifrost_inventory.py \
         /opt/stack/bifrost/playbooks/install.yaml

  4. After the install finishes, you can redeploy the servers again
     using ``run_bifrost.sh`` script.
