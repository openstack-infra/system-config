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
  * :file:`modules/kerberos`
  * :file:`modules/openstack_project/manifests/kdc.pp`
:Projects:
  * http://web.mit.edu/kerberos
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
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

Adding principals
-----------------

To add an admin principal::

   # execute kadmin.local then run these commands
   addprinc corvus/admin@OPENSTACK.ORG
