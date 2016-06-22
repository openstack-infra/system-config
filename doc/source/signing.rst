:title: Signing System

.. _nodepool:

Signing System
##############

Nodepool is a service used by the OpenStack CI team to deploy and manage a pool
of devstack images on a cloud server for use in OpenStack project testing.

At a Glance
===========

:Hosts:
  * signing01.ci.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/signing_node.pp`

Overview
========

This machine holds an unencrypted copy of the OpenPGP signing subkey
for ``OpenStack Infra (Some Cycle) <infra-root@openstack.org>``,
used to create detached signatures for release artifacts (tarballs,
wheels, et cetera) and to sign and push Git tags as part of our
managed release automation. It only runs CI jobs for tasks which
require access to this key, using only vetted tools and scripts
reviewed by the Infra team.


Storage
-------

While the signing subkey is present unencrypted on this system, the
corresponding master key is kept symmetrically encrypted in the root
home directory of the Infra systems management bastion instead. At
the time of key creation a revocation certificate is also generated,
for which Infra root sysadmins are encouraged to retrieve and keep
local copies in case control over or access to the original master
key is lost. In the future, the master key and revocation
certificate may be distributed across our root team rather than kept
in one place (for example using Shamir's secret sharing scheme
similar to what `the Debian Project does for its archive keys
<https://ftp-master.debian.org/keys.html>`).


Rotation
--------

The master key is rotated at the start of each development cycle,
signed by a majority of Infra root sysadmins before being put into
service, and has an expiration date set for shortly after the end of
the targeted development cycle. As each new key is created and
brought into rotation, an announcement should be signed by both the
old and new keys and sent to the
openstack-announce@lists.openstack.org mailing list. The new key
should also be signed by the old, and this signature pushed to the
public keyserver network. New key fingerprints are also submitted to
the openstack/releases repository, for publication on the
releases.openstack.org Web site.


Revocation
----------

Under normal circumstances, keys should be allowed to expire
gracefully. If the key is compromised but still accessible, a
revocation certificate can be generated and published to the key
network at that time. If access to the private key is lost
completely, the revocation certificate generated at key creation
time should be used as a last resort.


Management
==========

As process is solidified, this section will be updated with specific
commands and examples.
