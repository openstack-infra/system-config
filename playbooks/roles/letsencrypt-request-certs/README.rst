Request certificates from letsencrypt

The role requests certificates (or renews expiring certificates, which
is fundamentally the same thing) from letsencrypt for a host.  This
requires the ``acme.sh`` tool and driver which should have been
installed by the ``letsencrypt-acme-sh-install`` role.

This role does not create the certificates.  It will request the
certificates from letsencrypt and populate the authentication data
into the ``acme_txt_required`` variable.  These values need to be
installed and activated on the DNS server by the
``letsencrypt-install-txt-record`` role; the
``letsencrypt-create-certs`` will then finish the certificate
provision process.

**Role Variables**

.. zuul:rolevar:: letsencrypt_test_only

   Uses staging, rather than prodcution requests to letsencrypt

.. zuul:rolevar:: letsencrypt_certs

   A host wanting a certificate should define a dictionary variable
   ``letsencyrpt_certs``.  Each key in this dictionary is a separate
   certificate to create (i.e. a host can create multiple separate
   certificates).  Each key should have a list of hostnames valid for
   that certificate.  The certificate will be named for the *first*
   entry.

   For example:

   .. code-block:: yaml

     letsencrypt_certs:
        main:
           - hostname01.opendev.org
           - hostname.opendev.org
         secondary:
           - foo.opendev.org

   will ultimately result in two certificates being provisioned on the
   host in ``/etc/letsencrypt-certs/hostname01.opendev.org`` and
   ``/etc/letsencrypt-certs/foo.opendev.org``.

   Note that each entry will require a ``CNAME`` pointing the ACME
   challenge domain to the TXT record that will be created in the
   signing domain.  For example above, the following records would need
   to be pre-created::

     _acme-challenge.hostname01.opendev.org.  IN   CNAME  acme.opendev.org.
     _acme-challenge.hostname.opendev.org.    IN   CNAME  acme.opendev.org.
     _acme-challenge.foo.opendev.org.         IN   CNAME  acme.opendev.org.
