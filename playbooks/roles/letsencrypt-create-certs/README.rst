Generate letsencrypt certificates

This must run after the ``letsencrypt-install-acme-sh``,
``letsencrypt-request-certs`` and ``letsencrypt-install-txt-records``
roles.  It will run the ``acme.sh`` process to create the certificates
on the host.

**Role Variables**

.. zuul:rolevar:: letsencrypt_self_sign_only

   If set to True, will locally generate self-signed certificates in
   the same locations the real script would, instead of contacting
   letsencrypt.  This is set during gate testing as the
   authentication tokens are not available.

.. zuul:rolevar:: letsencrypt_use_staging

   If set to True will use the letsencrypt staging environment, rather
   than make production requests.  Useful during initial provisioning
   of hosts to avoid affecting production quotas.

.. zuul:rolevar:: letsencrypt_certs

   The same variable as described in ``letsencrypt-request-certs``.
