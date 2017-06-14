:title: Certificate Authority

.. _certificate_authority:

Certificate Authority
#####################

The cerfitificate authority services used for signing SSL certs in
openstack-infra.

At a Glance
===========

:Hosts:
  * puppetmaster.openstack.org
:Projects:
  * https://www.openssl.org/
:Documentation:
  * https://debian-administration.org/article/618/Certificate_Authority_CA_with_OpenSSL

Overview
========

As we start using SSL between more of our services, for example gearman, it has
become clear we should be running our own certificicate authority.

Generating a CA certificate
---------------------------

Below are the steps for create a new certificicate authority. Today we do this
on puppetmaster.openstack.org.  Some important things to note, our pass phrase
for our cakey.pem file is stored in our GPG password.txt file. Additionally, by
default our cacert.pem file will only be valid for 3 years by default.

.. code-block:: bash

    $ /usr/lib/ssl/misc/CA.sh -newca
    CA certificate filename (or enter to create)

    Making CA certificate ...
    Generating a 2048 bit RSA private key
    ...............................................................+++
    .......+++
    writing new private key to './demoCA/private/./cakey.pem'
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [AU]:CA
    State or Province Name (full name) [Some-State]:Texas
    Locality Name (eg, city) []:Austin
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:OpenStack Foundation
    Organizational Unit Name (eg, section) []:Infrastructure
    Common Name (e.g. server FQDN or YOUR name) []:puppetmaster.openstack.org
    Email Address []:openstack-infra@lists.openstack.org

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:
    Using configuration from /usr/lib/ssl/openssl.cnf
    Enter pass phrase for ./demoCA/private/./cakey.pem:
    Check that the request matches the signature
    Signature ok
    Certificate Details:
            Serial Number: 15153659883634025817 (0xd24c9d606b17e559)
            Validity
                Not Before: Jun 14 15:22:14 2017 GMT
                Not After : Jun 13 15:22:14 2020 GMT
            Subject:
                countryName               = CA
                stateOrProvinceName       = Texas
                organizationName          = OpenStack Foundation
                organizationalUnitName    = Infrastructure
                commonName                = puppetmaster.openstack.org
                emailAddress              = openstack-infra@lists.openstack.org
            X509v3 extensions:
                X509v3 Subject Key Identifier:
                    9B:FB:A2:07:32:9D:AE:D8:A5:95:FA:7A:D2:2E:14:CD:9E:66:4A:CF
                X509v3 Authority Key Identifier:
                    keyid:9B:FB:A2:07:32:9D:AE:D8:A5:95:FA:7A:D2:2E:14:CD:9E:66:4A:CF

                X509v3 Basic Constraints:
                    CA:TRUE
    Certificate is to be certified until Jun 13 15:22:14 2020 GMT (1095 days)

    Write out database with 1 new entries
    Data Base Updated

