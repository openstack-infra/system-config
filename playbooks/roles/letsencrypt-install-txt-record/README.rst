letsencrypt-install-txt-record
------------------------------

Install TXT records to the ``acme.opendev.org`` domain.  This role
runs only the adns server, and assumes ownership of the
``/var/lib/bind/zones/acme.opendev.org/zone.db`` file.  After
installation the nameserver is refreshed.

After this, ``letsencrypt-create-certs`` can run on each host to
provision the certificates.

**Role Variables**

.. zuul:rolevar:: acme_txt_required

   A global dictionary of TXT records to be installed.  This is
   generated in a prior step on each host by the
   ``letsencrypt-request-certs`` role.


