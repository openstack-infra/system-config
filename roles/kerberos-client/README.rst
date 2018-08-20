An ansible role to configure a kerberos client

**Role Variables**

.. zuul:rolevar:: kerberos_realm

   The realm for Kerberos authentication.  You must set the realm.
   e.g. ``MY.COMPANY.COM``.  This will be the default realm.

.. zuul:rolevar:: kerberos_admin_server
   :default: {{ ansible_fqdn }}

   The host where the administraion server is running.  Typically this
   is the master Kerberos server.

.. zuul:rolevar:: kerberos_kdcs
   :default: [ {{ ansible_fqdn }} ]

   A list of key distribution center (KDC) hostnames for the realm.

