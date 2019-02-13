letsencrypt-create-certs
========================

Generate letsencrypt certificates.  Needs to be called *after* TXT
records are installed into DNS.

**Role Variables**

.. zuul:rolevar:: letsencrypt_certs

   This is a dictionary argument that specifies the letsencrypt
   certificates.  The host will create the certificates specified for
   it in this dictionary.
