:title: Kerberos

.. _kerberos:

Kerberos
########

Kerberos is a computer network authentication protocol which works on the
basis of 'tickets' to allow nodes communicating over a non-secure network
to prove their identity to one another in a secure manner. It is the basis
for authentication to AFS.

At a Glance
===========

:Hosts:
  * kdc*.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-kerberos/tree/
  * :file:`modules/openstack_project/manifests/kdc.pp`
:Projects:
  * http://web.mit.edu/kerberos
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * http://krbdev.mit.edu/rt/
:Resources:
  * `Kerberos Website <http://web.mit.edu/kerberos>`_
  * `KDC Install guide <http://web.mit.edu/kerberos/krb5-devel/doc/admin/install_kdc.html>`_

OpenStack Realm
---------------

OpenStack runs a Kerberos ``Realm`` called ``OPENSTACK.ORG``.
The realm contains a ``Key Distribution Center`` or KDC which is spread
across a master and a slave, as well as an admin server which only runs on the
master. Most of the configuration is in puppet, but initial setup and
the management of user accounts, known as ``principals``, are manual tasks.

Realm Creation
--------------

On the first KDC host, the admin needs to run `krb5_newrealm` by hand. Then
admin principals and host principles need to be set up.

Set up host principals for slave propogation::

   # execute kadmin.local then run these commands
   addprinc -randkey host/kdc01.openstack.org
   addprinc -randkey host/kdc02.openstack.org
   ktadd host/kdc01.openstack.org
   ktadd host/kdc02.openstack.org

Copy the file `/etc/krb5.keytab` to the second kdc host.

The puppet config sets up slave propogation scripts and cron jobs to run them.

.. _addprinc:

Adding principals
-----------------

First, ensure the user has an entry in puppet so they have a unix
shell account on our hosts.  SSH access is not necessary, but keeping
track of usernames and uids with account entries is necessary.

Then, add the user to Kerberos using kadmin (while authenticated as a
kerberos admin) or kadmin.local on the kdc::

  kadmin: addprinc $USERNAME@OPENSTACK.ORG

Where `$USERNAME` is the lower-case username of their unix account in
puppet.  `OPENSTACK.ORG` should be capitalized.

If you are adding an admin principal, use
`username/admin@OPENSTACK.ORG`.  Admins should additionally have
regular user principals.
