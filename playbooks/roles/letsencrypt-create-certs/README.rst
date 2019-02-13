letsencrypt-create-certs
------------------------

Generate letsencrypt certificates.

This must run after the ``letsencrypt-install-acme-sh``,
``letsencrypt-request-certs`` and ``letsencrypt-install-txt-records``
roles.  It will run the ``acme.sh`` process to create the certificates
on the host.

**Role Variables**

.. zuul:rolevar:: letsencrypt_test_only

   If set to True, will locally generate self-signed certificates in
   the same locations the real script would, instead of contacting
   letsencrypt.  This is set during gate testing as the
   authentication tokens are not available.

.. zuul:rolevar:: letsencrypt_certs

   The same variable as described in ``letsencrypt-request-certs``.
