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

puppetmaster.openstack.org:/root/signing.gnupg/gpg.conf::

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

.. code-block:: shell-session

    root@puppetmaster:~# umask 077
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

    root@puppetmaster:~# gpg --homedir signing.gnupg --output signing.gnupg/revoke.asc --gen-revoke 0x120D3C23C6D5584D
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
    root@puppetmaster:~# gpg --homedir signing.gnupg --send-keys 0x120D3C23C6D5584D 0xC0224DB5F541FB68
    [output pending, there are issues with the SKS keyservers at the moment]
    root@puppetmaster:~# mkdir temporary.gnupg
    root@puppetmaster:~# gpg --homedir signing.gnupg --output temporary.gnupg/secret-subkeys --export-secret-subkeys 0xC0224DB5F541FB68\!
    root@puppetmaster:~# gpg --homedir temporary.gnupg --import temporary.gnupg/secret-subkeys
    gpg: keyring `temporary.gnupg/secring.gpg' created
    gpg: keyring `temporary.gnupg/pubring.gpg' created
    gpg: key C6D5584D: secret key imported
    gpg: temporary.gnupg/trustdb.gpg: trustdb created
    gpg: key C6D5584D: public key "OpenStack Infra (Some Cycle) <infra-root@openstack.org>" imported
    gpg: Total number processed: 1
    gpg:               imported: 1  (RSA: 1)
    gpg:       secret keys read: 1
    gpg:   secret keys imported: 1
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
    root@puppetmaster:~# /opt/system-config/production/tools/hieraedit.py --yaml /opt/system-config/hieradata/production/group/signing.yaml -f temporary.gnupg/pubring.gpg pubring
    root@puppetmaster:~# /opt/system-config/production/tools/hieraedit.py --yaml /opt/system-config/hieradata/production/group/signing.yaml -f temporary.gnupg/secring.gpg secring
    root@puppetmaster:~# shred temporary.gnupg/*
    root@puppetmaster:~# rm -rf temporary.gnupg
