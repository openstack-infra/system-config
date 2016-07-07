:title: Signing System

.. _signing:

Signing System
##############

This machine corresponds to the ``signing`` node label in job
configuration, holding an unencrypted copy of the OpenPGP signing
subkey for ``OpenStack Infra (Some Cycle)
<infra-root@openstack.org>`` used to create detached signatures for
release artifacts (tarballs, wheels, et cetera) and to sign and push
Git tags as part of our managed release automation. It only runs CI
jobs for tasks which require access to this key, using only vetted
tools and scripts reviewed by the Infra team.


At a Glance
===========

:Hosts:
  * signing*.ci.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/signing_node.pp`


Key Management Overview
=======================

The signing server is a fairly typical long-lived job node,
distinguished primarily by having the signing subkey pair installed
by Puppet into the job runner account's home directory from binary
blobs in hiera. These blobs correspond to the
``~/.gnupg/pubring.gpg`` and ``~/.gnupg/secring.gpg`` files of a
freshly initialized gpg config after importing a minimal unencrypted
export on the management bastion of only the desired signing subkey
from the ``/root/signing.gunpg`` directory.


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


Key Management Process
======================

Configuration
-------------

This is the content of the ``/root/signing.gnupg/gpg.conf`` file on
our management bastion host::

    # A basic gpg.conf using secure keyserver transport and some more
    # verbose display options. This configuration assumes you have
    # installed both the gnupg and gnupg-curl packages. Set your umask
    # to 077, create a /root/signing.gnupg directory and place this
    # configuration file in it.
    #
    # Retrieve and validate the HKPS key for the SKS keyservers this way:
    #
    #     wget -P ~/signing.gnupg/ \
    #         https://sks-keyservers.net/sks-keyservers.netCA.pem{,.asc}
    #     gpg --homedir signing.gnupg --recv-key \
    #         0x94CBAFDD30345109561835AA0B7F8B60E3EDFAE3
    #     gpg --homedir signing.gnupg --verify \
    #         ~/signing.gnupg/sks-keyservers.netCA.pem{.asc,}

    # Receive, send and search for keys in the SKS keyservers pool using
    # HKPS (OpenPGP HTTP Keyserver Protocol via TLS/SSL).
    keyserver hkps://hkps.pool.sks-keyservers.net

    # Set the path to the public certificate for the
    # sks-keyservers.net CA used to verify connections to servers in
    # the pool above.
    keyserver-options ca-cert-file=/root/signing.gnupg/sks-keyservers.netCA.pem

    # Ignore keyserver URLs specified in retrieved/refreshed keys
    # so they don't direct you to update from non-HKPS sources.
    keyserver-options no-honor-keyserver-url

    # Display key IDs in a more accurate 16-digit hexidecimal format
    # and add 0x at the beginning for clarity.
    keyid-format 0xlong

    # Display the calculated validity of user IDs when listing keys or
    # showing signatures.
    list-options show-uid-validity
    verify-options show-uid-validity


Generation
----------

Key generation should happen reasonably far in advance of expiration
of the old key (at least a month), so as to provide ample time for a
majority of our root sysadmins to attest to the key and provide
warning to the rest of the community of the upcoming transition. Of
course, if this is being done to replace a revoked key, this
timeline should be accelerated as much as possible to provide
continuity of service so use your best judgement on a balance of
sufficient attestation and warning (same-day turnaround is
preferred).

Make sure we start with a restrictive umask so that files and
directories we write from this point forward are only accessible by
the root user:

.. code-block:: shell-session

    root@puppetmaster:~# umask 077

Now create a master key for the coming development cycle, taking
mostly the GnuPG recommended default values. Set a validity period
sufficient to last through the release process at the conclusion of
the cycle. Use a sufficiently long, randomly-generated passphrase
string (it's fine to reuse the one stored in our passwords list for
earlier keys unless we know it to have been compromised):

.. code-block:: shell-session

    root@puppetmaster:~# gpg --homedir signing.gnupg --gen-key
    gpg (GnuPG) 1.4.16; Copyright (C) 2013 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

    Please select what kind of key you want:
       (1) RSA and RSA (default)
       (2) DSA and Elgamal
       (3) DSA (sign only)
       (4) RSA (sign only)
    Your selection?
    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048)
    Requested keysize is 2048 bits
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0) 7m
    Key expires at Thu 02 Feb 2017 08:41:39 PM UTC
    Is this correct? (y/N) y

    You need a user ID to identify your key; the software constructs the user ID
    from the Real Name, Comment and Email Address in this form:
        "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"

    Real name: OpenStack Infra
    Email address: infra-root@openstack.org
    Comment: Some Cycle
    You selected this USER-ID:
        "OpenStack Infra (Some Cycle) <infra-root@openstack.org>"

    Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
    You need a Passphrase to protect your secret key.

    Enter passphrase: ********************************
    Repeat passphrase: ********************************

    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.
    .+++++
    ......+++++
    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.
    .+++++
    +++++
    gpg: key 0x120D3C23C6D5584D marked as ultimately trusted
    public and secret key created and signed.

    gpg: checking the trustdb
    gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
    gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
    gpg: next trustdb check due at 2017-02-02
    pub   2048R/0x120D3C23C6D5584D 2016-07-07 [expires: 2017-02-02]
          Key fingerprint = 7222 E5A0 5730 B767 0F93  035A 120D 3C23 C6D5 584D
    uid                 [ultimate] OpenStack Infra (Some Cycle) <infra-root@openstack.org>
    sub   2048R/0x1F215B56867C5D9A 2016-07-07 [expires: 2017-02-02]

Create a revocation certificate for the master key, for use in the
case extreme case that this master key itself becomes inaccessible,
for example because the decryption passphrase is lost (under any
other circumstances, a revocation certificate with a more detailed
description can be generated using the master key on an as-needed
basis):

.. code-block:: shell-session

    root@puppetmaster:~# gpg --homedir signing.gnupg --output \
    > signing.gnupg/revoke.asc --gen-revoke 0x120D3C23C6D5584D
    sec  2048R/0x120D3C23C6D5584D 2016-07-07 OpenStack Infra (Some Cycle) <infra-root@openstack.org>

    Create a revocation certificate for this key? (y/N) y
    Please select the reason for the revocation:
      0 = No reason specified
      1 = Key has been compromised
      2 = Key is superseded
      3 = Key is no longer used
      Q = Cancel
    (Probably you want to select 1 here)
    Your decision? 1
    Enter an optional description; end it with an empty line:
    > This revocation is to be used in the event the key cannot be recovered.
    >
    Reason for revocation: Key has been compromised
    This revocation is to be used in the event the key cannot be recovered.
    Is this okay? (y/N) y

    You need a passphrase to unlock the secret key for
    user: "OpenStack Infra (Some Cycle) <infra-root@openstack.org>"
    2048-bit RSA key, ID 0x120D3C23C6D5584D, created 2016-07-07

    Enter passphrase: ********************************

    ASCII armored output forced.
    Revocation certificate created.

    Please move it to a medium which you can hide away; if Mallory gets
    access to this certificate he can use it to make your key unusable.
    It is smart to print this certificate and store it away, just in case
    your media become unreadable.  But have some caution:  The print system of
    your machine might store the data and make it available to others!

Use the interactive key editor to add a subkey constrained to
signing purposes only. It does not need an expiration since it will
be valid only for as long as its associated master key is valid:

.. code-block:: shell-session

    root@puppetmaster:~# gpg --homedir signing.gnupg --edit-key 0x120D3C23C6D5584D
    gpg (GnuPG) 1.4.16; Copyright (C) 2013 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

    Secret key is available.

    pub  2048R/0x120D3C23C6D5584D  created: 2016-07-07  expires: 2017-02-02  usage: SC
                                   trust: ultimate      validity: ultimate
    sub  2048R/0x1F215B56867C5D9A  created: 2016-07-07  expires: 2017-02-02  usage: E
    [ultimate] (1). OpenStack Infra (Some Cycle) <infra-root@openstack.org>

    gpg> addkey
    Key is protected.

    You need a passphrase to unlock the secret key for
    user: "OpenStack Infra (Some Cycle) <infra-root@openstack.org>"
    2048-bit RSA key, ID 0x120D3C23C6D5584D, created 2016-07-07

    Enter passphrase: ********************************

    Please select what kind of key you want:
       (3) DSA (sign only)
       (4) RSA (sign only)
       (5) Elgamal (encrypt only)
       (6) RSA (encrypt only)
    Your selection? 4
    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048)
    Requested keysize is 2048 bits
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0)
    Key does not expire at all
    Is this correct? (y/N) y
    Really create? (y/N) y
    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.
    +++++
    ........+++++

    pub  2048R/0x120D3C23C6D5584D  created: 2016-07-07  expires: 2017-02-02  usage: SC
                               trust: ultimate      validity: ultimate
    sub  2048R/0x1F215B56867C5D9A  created: 2016-07-07  expires: 2017-02-02  usage: E
    sub  2048R/0xC0224DB5F541FB68  created: 2016-07-07  expires: never       usage: S
    [ultimate] (1). OpenStack Infra (Some Cycle) <infra-root@openstack.org>

    gpg> save

Now send the master key to the keyserver network. The subkeys are
all submitted along with it, so do not need to be specified
separately:

.. code-block:: shell-session

    root@puppetmaster:~# gpg --homedir signing.gnupg --send-keys 0x120D3C23C6D5584D
    sending key 0x120D3C23C6D5584D to hkps server hkps.pool.sks-keyservers.net

The rest of this process shouldn't happen until we're ready for the
signing system to transition to our new key. In a typical,
non-emergency rotation this should not happen until release
activities for the previous cycle have concluded so that we don't
inadvertently sign their artifacts with the new key.

Create a new GnuPG keychain by exporting a copy of just the signing
subkey to a file and then importing that (and only that) in a new
GnuPG directory:

.. code-block:: shell-session

    root@puppetmaster:~# mkdir temporary.gnupg
    root@puppetmaster:~# gpg --homedir signing.gnupg --output \
    > temporary.gnupg/secret-subkeys --export-secret-subkeys 0xC0224DB5F541FB68\!
    root@puppetmaster:~# gpg --homedir temporary.gnupg --import \
    > temporary.gnupg/secret-subkeys
    gpg: keyring `temporary.gnupg/secring.gpg' created
    gpg: keyring `temporary.gnupg/pubring.gpg' created
    gpg: key C6D5584D: secret key imported
    gpg: temporary.gnupg/trustdb.gpg: trustdb created
    gpg: key C6D5584D: public key "OpenStack Infra (Some Cycle) <infra-root@openstack.org>" imported
    gpg: Total number processed: 1
    gpg:               imported: 1  (RSA: 1)
    gpg:       secret keys read: 1
    gpg:   secret keys imported: 1

So that our CI jobs will be able to make use of this subkey without
interactively supplying a passphrase, the old passphrase (exported
from the master key) must be reset to an empty string in the new
temporary copy. This is again done using an interactive key editor
session:

.. code-block:: shell-session

    root@puppetmaster:~# gpg --homedir temporary.gnupg --edit-key 0xC0224DB5F541FB68
    gpg (GnuPG) 1.4.16; Copyright (C) 2013 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.

    Secret key is available.

    pub  2048R/C6D5584D  created: 2016-07-07  expires: 2017-02-02  usage: SC
                     trust: unknown       validity: unknown
    sub  2048R/F541FB68  created: 2016-07-07  expires: never       usage: S
    [ unknown] (1). OpenStack Infra (Some Cycle) <infra-root@openstack.org>

    gpg> passwd
    Secret parts of primary key are not available.

    You need a passphrase to unlock the secret key for
    user: "OpenStack Infra (Some Cycle) <infra-root@openstack.org>"
    2048-bit RSA key, ID F541FB68, created 2016-07-07

    Enter passphrase: ********************************

    Enter the new passphrase for this secret key.

    Enter passphrase:
    Repeat passphrase:

    You don't want a passphrase - this is probably a *bad* idea!

    Do you really want to do this? (y/N) y

    gpg> save

This leaves us with a temporary keyring containing only an
unencrypted copy of the signing subkey. Push this into private hiera
so that it will be installed onto the signing system by our
configuration management:

.. code-block:: shell-session

    root@puppetmaster:~# /opt/system-config/production/tools/hieraedit.py --yaml \
    > /opt/system-config/hieradata/production/group/signing.yaml -f \
    > temporary.gnupg/pubring.gpg pubring
    root@puppetmaster:~# /opt/system-config/production/tools/hieraedit.py --yaml \
    > /opt/system-config/hieradata/production/group/signing.yaml -f \
    > temporary.gnupg/secring.gpg secring

Finally, do your best to securely remove the temporary copy of the
unencrypted signing subkey and any associated files:

.. code-block:: shell-session

    root@puppetmaster:~# shred temporary.gnupg/*
    root@puppetmaster:~# rm -rf temporary.gnupg


Attestation
-----------

We need a majority (if not all) of our current root sysadmins to
verify and attest to the authenticity of our artifact signing key,
because it represents a system maintained by our team rather than
representing some particular individual and so anyone else attesting
to this key can really only do so transitively through us. This
should be done soon after a new key is minted (preferably the same
week) so that others in the community who wish to extend the web of
trust around the key based on our attestations (for example, release
managers or team leads) have an opportunity to do so before it's put
into production.

Start by logging into the management bastion and examining the
fingerprint of the key as it exists on disk:

.. code-block:: shell-session

    me@puppetmaster:~$ sudo gpg --homedir /root/signing.gnupg --fingerprint \
    > --list-keys "OpenStack Infra (Newton Cycle)"
    pub   2048R/0x120D3C23C6D5584D 2016-07-07 [expires: 2017-02-02]
          Key fingerprint = 120D 3C23 C6D5 584D 6FC2  4646 64DB B05A CC5E 7C28
    uid                 [ultimate] OpenStack Infra (Some Cycle) <infra-root@openstack.org>
    sub   2048R/0x1F215B56867C5D9A 2016-07-07 [expires: 2017-02-02]
    sub   2048R/0xC0224DB5F541FB68 2016-07-07

Now on your own system where your OpenPGP key resides, retrieve the
key, compare the fingerprint from above, and if they match, sign it
and push the signature back to the keyserver network:

.. code-block:: shell-session

    me@home:~$ gpg2 --recv-keys 0x120D3C23C6D5584D
    gpg: requesting key 0x120D3C23C6D5584D from hkps server hkps.pool.sks-keyservers.net
    gpg: key 0x120D3C23C6D5584D: public key "OpenStack Infra (Some Cycle) <infra-root@openstack.org>" imported
    gpg: 3 marginal(s) needed, 1 complete(s) needed, classic trust model
    gpg: depth: 0  valid:   3  signed:  31  trust: 0-, 0q, 0n, 0m, 0f, 3u
    gpg: depth: 1  valid:  31  signed:  46  trust: 30-, 0q, 0n, 0m, 1f, 0u
    gpg: next trustdb check due at 2016-11-30
    gpg: Total number processed: 1
    gpg:               imported: 1  (RSA: 1)
    me@home:~$ gpg2 --fingerprint 0x120D3C23C6D5584D
    pub   2048R/0x120D3C23C6D5584D 2016-07-07 [expires: 2017-02-02]
          Key fingerprint = 120D 3C23 C6D5 584D 6FC2  4646 64DB B05A CC5E 7C28
    uid                 [  full  ] OpenStack Infra (Some Cycle) <infra-root@openstack.org>
    sub   2048R/0x1F215B56867C5D9A 2016-07-07 [expires: 2017-02-02]
    sub   2048R/0xC0224DB5F541FB68 2016-07-07
    me@home:~$ gpg2 --sign-key 0x120D3C23C6D5584D

    pub  2048R/0x120D3C23C6D5584D  created: 2016-07-07  expires: 2017-02-02  usage: SC
                                   trust: unknown       validity: full
    sub  2048R/0x1F215B56867C5D9A  created: 2016-07-07  expires: 2017-02-02  usage: E
    sub  2048R/0xC0224DB5F541FB68  created: 2016-07-07  expires: never       usage: S
    [  full  ] (1). OpenStack Infra (Some Cycle) <infra-root@openstack.org>


    pub  2048R/0x120D3C23C6D5584D  created: 2016-07-07  expires: 2017-02-02  usage: SC
                                   trust: unknown       validity: full
     Primary key fingerprint: 120D 3C23 C6D5 584D 6FC2  4646 64DB B05A CC5E 7C28

         OpenStack Infra (Some Cycle) <infra-root@openstack.org>

    This key is due to expire on 2017-02-02.
    Are you sure that you want to sign this key with your
    key "My Name <me@example.org>" (0xAB54A98CEB1F0AD2)

    Really sign? (y/N) y

       +-----------------------------------------------------------------------+
       | Please enter the passphrase to unlock the secret key for the OpenPGP  |
       | certificate:                                                          |
       | "My Name <me@example.org>"                                            |
       | 2048-bit RSA key, ID 0xAB54A98CEB1F0AD2,                              |
       | created 2008-09-10.                                                   |
       |                                                                       |
       |                                                                       |
       | Passphrase **********************____________________________________ |
       |                                                                       |
       |          <OK>                                         <Cancel>        |
       +-----------------------------------------------------------------------+

    me@home:~$ gpg2 --send-keys 0x120D3C23C6D5584D
    gpg: sending key 0x120D3C23C6D5584D to hkps server hkps.pool.sks-keyservers.net
