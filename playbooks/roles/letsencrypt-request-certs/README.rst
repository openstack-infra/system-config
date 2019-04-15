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

.. zuul:rolevar:: letsencrypt_use_staging

   If set to True will use the letsencrypt staging environment, rather
   than make production requests.  Useful during initial provisioning
   of hosts to avoid affecting production quotas.

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
       hostname-main-cert:
         - hostname01.opendev.org
         - hostname.opendev.org
       hostname-secondary-cert:
         - foo.opendev.org

   will ultimately result in two certificates being provisioned on the
   host in ``/etc/letsencrypt-certs/hostname01.opendev.org`` and
   ``/etc/letsencrypt-certs/foo.opendev.org``.

   Note the creation role ``letsencrypt-create-certs`` will call a
   handler ``letsencrypt updated {{ key }}`` (for example,
   ``letsencrypt updated hostname-main-cert``) when that certificate
   is created or updated.  Because Ansible errors if a handler is
   called with no listeners, you *must* define a listener for event.
   ``letsencrypt-create-certs`` has ``handlers/main.yaml`` where
   handlers can be defined.  Since handlers reside in a global
   namespace, you should choose an appropriately unique name.

   Note that each entry will require a ``CNAME`` pointing the ACME
   challenge domain to the TXT record that will be created in the
   signing domain.  For example above, the following records would need
   to be pre-created::

     _acme-challenge.hostname01.opendev.org.  IN   CNAME  acme.opendev.org.
     _acme-challenge.hostname.opendev.org.    IN   CNAME  acme.opendev.org.
     _acme-challenge.foo.opendev.org.         IN   CNAME  acme.opendev.org.
