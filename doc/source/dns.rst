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

To add a new zone, add an entry to :file:`manifests/site.pp`,
:file:`modules/openstack_project/manifests/master_nameserver.pp` and
create a new git repository to hold the contents of the zone.

Run::

  dnssec-keygen -a RSASHA256 -b 2048 -3 example.net
  dnssec-keygen -a RSASHA256 -b 2048 -3 -fx example.net

And add the resulting files to the `dnssec_keys` key in the
`group/adns.yaml` private hiera file on puppetmaster.

.. note:: This section will be expanded.
