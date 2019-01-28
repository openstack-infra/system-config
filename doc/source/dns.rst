:title: DNS

.. _dns:

DNS
###

The project runs authoritative DNS servers for any constituent
projects that wish to use them.  The servers run Bind on a hidden
master which handles automatic DNSSEC zone signing while the public
authoritative servers run NSD.

At a Glance
===========

:Hosts:
  * ns1.opendev.org
  * ns2.opendev.org
:Ansible:
  * :cgit_file:`playbooks/group_vars/dns.yaml`
:Projects:
  * https://www.nlnetlabs.nl/projects/nsd/
  * https://www.isc.org/downloads/bind/doc/

Adding a Zone
=============

To add a new zone, identify an existing git repository or create a new
one to hold the contents of the zone, then update
:cgit_file:`playbooks/group_vars/dns.yaml`.

Run::

  dnssec-keygen -a RSASHA256 -b 2048 -3 example.net
  dnssec-keygen -a RSASHA256 -b 2048 -3 -fk example.net

And add the resulting files to the `dnssec_keys` key in the
`group/adns.yaml` private hostvars file on puppetmaster.

If you need to generate DS records for the registrar, identify which
of the just-created key files is the key-signing key by examining the
contents of the files and reading the comments therein, then run::

  dnssec-dsfromkey -2 $KEYFILE
