:title: DNS

.. _dns:

DNS
###

The project runs authoritative DNS servers for any constituent
projects that wish to use them.  The servers run NSD.

At a Glance
===========

:Hosts:
  * ns1.openstack.org
  * ns2.openstack.org
:Puppet:
  * :file:`manifests/site.pp`
:Projects:
  * https://github.com/icann-dns/puppet-nsd
  * https://www.nlnetlabs.nl/projects/nsd/

Adding a Zone
=============

To add a new zone, add an entry to :file:`manifests/site.pp`, and
create a new git repository to hold the contents of the zone.

.. note:: This section will be expanded.
