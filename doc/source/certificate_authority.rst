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

Today we have a single CA service setup on puppetmaster.o.o:

  /etc/zuul-ca

This is used for generating SSL certificates needed by our CI systems.  As we
need to create more SSL certificates for new services, we'll create additional
directories on puppetmaster.openstack.org, having multiple CA services.

Generating a CA certificate
---------------------------

Below are the steps for create a new certificicate authority. Today we do this
on puppetmaster.openstack.org.  Some important things to note, our pass phrase
for our cakey.pem file is stored in our GPG password.txt file. Additionally, by
default our cacert.pem file will only be valid for 3 years.

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
    Common Name (e.g. server FQDN or YOUR name) []:zuulv3.openstack.org
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
                commonName                = zuulv3.openstack.org
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

Generate a Cerfificate Request
------------------------------

Each service that requires a SSL certificate will need to first request a
certificate.  Below we'll be create the private key for a gearman server.

.. code-block:: bash

	$ /usr/lib/ssl/misc/CA.sh -newreq-nodes
	Generating a 2048 bit RSA private key
	.......+++
	....+++
	writing new private key to 'newreq.pem'
	-----
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) [AU]:US
	State or Province Name (full name) [Some-State]:Texas
	Locality Name (eg, city) []:Austin
	Organization Name (eg, company) [Internet Widgits Pty Ltd]:OpenStack Foundation
	Organizational Unit Name (eg, section) []:Infrastructure
	Common Name (e.g. server FQDN or YOUR name) []:Gearman server
	Email Address []:openstack-infra@lists.openstack.org

	Please enter the following 'extra' attributes
	to be sent with your certificate request
	A challenge password []:
	An optional company name []:
	Request (and private key) is in newreq.pem

Signing a Certificate Request
-----------------------------

Next we need to sign the request from above, which creates the public
certificate for our service to run. By default SSL certificates are valid for 1
year.

.. code-block:: bash

	$ /usr/lib/ssl/misc/CA.sh -sign
	Using configuration from /usr/lib/ssl/openssl.cnf
	Enter pass phrase for ./demoCA/private/cakey.pem:
	Check that the request matches the signature
	Signature ok
	Certificate Details:
	        Serial Number: 12264554420616840337 (0xaa347343e1504491)
	        Validity
	            Not Before: Jun 14 17:03:41 2017 GMT
	            Not After : Jun 14 17:03:41 2018 GMT
	        Subject:
	            countryName               = US
	            stateOrProvinceName       = Texas
	            localityName              = Austin
	            organizationName          = OpenStack Foundation
	            organizationalUnitName    = Infrastructure
	            commonName                = gearman server
	            emailAddress              = openstack-infra@lists.openstack.org
	        X509v3 extensions:
	            X509v3 Basic Constraints:
	                CA:FALSE
	            Netscape Comment:
	                OpenSSL Generated Certificate
	            X509v3 Subject Key Identifier:
	                97:4B:C1:CA:32:35:6E:79:25:E3:5E:E7:11:9C:29:3F:14:01:EB:5E
	            X509v3 Authority Key Identifier:
	                keyid:BE:45:50:BB:4F:F5:94:80:E2:12:03:95:80:9E:14:19:ED:E5:C6:4E

	Certificate is to be certified until Jun 14 17:03:41 2018 GMT (365 days)
	Sign the certificate? [y/n]:y


	1 out of 1 certificate requests certified, commit? [y/n]y
	Write out database with 1 new entries
	Data Base Updated
	Certificate:
	    Data:
	        Version: 3 (0x2)
	        Serial Number: 12264554420616840337 (0xaa347343e1504491)
	    Signature Algorithm: sha256WithRSAEncryption
	        Issuer: C=CA, ST=Texas, O=OpenStack Foundation, OU=Infrastructure, CN=zuulv3.openstack.org/emailAddress=openstack-infra@lists.openstack.org
	        Validity
	            Not Before: Jun 14 17:03:41 2017 GMT
	            Not After : Jun 14 17:03:41 2018 GMT
	        Subject: C=US, ST=Texas, L=Austin, O=OpenStack Foundation, OU=Infrastructure, CN=gearman server/emailAddress=openstack-infra@lists.openstack.org
	        Subject Public Key Info:
	            Public Key Algorithm: rsaEncryption
	                Public-Key: (2048 bit)
	                Modulus:
	                    00:ce:60:21:c1:c8:89:db:e6:13:fb:51:77:0f:4c:
	                    3b:e3:35:5e:06:cf:57:5f:87:4a:61:df:61:1d:b9:
	                    44:75:d4:0b:9d:47:de:8b:b1:28:d6:fb:54:34:43:
	                    9a:96:09:28:aa:9d:c5:aa:80:cb:27:5a:11:4c:f8:
	                    14:8a:08:8a:aa:a8:7c:e5:e8:ab:0a:17:29:9c:15:
	                    d7:2b:0b:46:f5:7a:2f:d1:75:68:30:fd:d4:10:18:
	                    ef:86:76:04:6a:54:62:27:cd:c4:73:bb:7c:6a:fa:
	                    19:9c:31:09:f0:71:5e:af:32:35:df:03:96:5a:55:
	                    b3:43:c7:de:f9:9f:85:e2:d5:fa:d2:08:b9:53:13:
	                    9f:b4:5f:e5:f6:2a:b5:40:f0:d8:f2:7a:60:d8:b1:
	                    65:0c:0c:18:1c:f6:bc:bd:64:d6:44:98:74:93:19:
	                    75:05:ef:5c:a8:94:e9:e5:9a:e7:c7:c4:8d:67:22:
	                    7a:9d:f0:17:df:74:27:72:cf:c1:81:71:73:fe:aa:
	                    5b:6c:74:4e:47:ef:29:11:52:b4:c8:8e:92:54:b4:
	                    53:db:9d:29:6b:ad:3a:40:a4:87:7c:ec:fd:d5:f2:
	                    39:5e:a4:26:2d:12:88:cd:62:56:11:bf:17:08:cb:
	                    76:93:6b:fd:7b:64:41:41:0c:f8:58:2a:fa:9f:25:
	                    cc:0f
	                Exponent: 65537 (0x10001)
	        X509v3 extensions:
	            X509v3 Basic Constraints:
	                CA:FALSE
	            Netscape Comment:
	                OpenSSL Generated Certificate
	            X509v3 Subject Key Identifier:
	                97:4B:C1:CA:32:35:6E:79:25:E3:5E:E7:11:9C:29:3F:14:01:EB:5E
	            X509v3 Authority Key Identifier:
	                keyid:BE:45:50:BB:4F:F5:94:80:E2:12:03:95:80:9E:14:19:ED:E5:C6:4E

	    Signature Algorithm: sha256WithRSAEncryption
	         39:59:b2:db:a1:6d:b5:28:37:c6:9f:74:9a:3f:80:e1:4c:ac:
	         9d:cd:26:06:86:7e:10:0c:0e:b2:96:94:57:37:0e:03:0f:f1:
	         55:d5:13:f3:dd:8a:4f:3f:fa:fc:d3:d5:96:d3:cc:79:a9:a7:
	         80:7f:a0:69:55:43:3f:d7:ab:b3:e9:c8:18:92:93:4c:75:cb:
	         d8:74:5a:70:7a:dc:79:9e:7f:70:b5:c1:39:c9:c7:a8:38:98:
	         2f:5c:df:40:df:3f:69:8d:17:6e:2f:01:d0:ec:dc:3a:55:1d:
	         9b:b3:0f:b5:5f:00:d2:8d:cf:d7:dc:5c:76:97:62:b3:ed:7e:
	         e4:51:59:a0:a0:a1:d7:d6:ec:93:ba:37:84:00:22:15:37:6c:
	         3b:94:7e:b4:e1:7f:ef:eb:a7:37:99:19:ec:0f:cc:b2:2a:21:
	         3f:44:37:bb:c1:36:4f:26:11:37:4f:0d:af:7f:84:4c:2f:6a:
	         bc:1f:49:d5:bf:da:c8:34:4e:aa:c1:d8:c9:9a:20:77:db:7e:
	         33:ff:e9:f9:28:97:e8:47:92:13:f7:86:0d:65:eb:f4:a8:0b:
	         4d:a1:ac:a4:43:68:84:4c:5c:46:61:6a:a2:32:b6:5b:d8:d6:
	         fe:f0:55:ee:08:8a:20:d0:c1:d5:40:7f:e5:ec:fb:c8:7b:13:
	         01:83:c8:da
	-----BEGIN CERTIFICATE-----
	MIIEWzCCA0OgAwIBAgIJAKo0c0PhUESRMA0GCSqGSIb3DQEBCwUAMIGoMQswCQYD
	VQQGEwJDQTEOMAwGA1UECAwFVGV4YXMxHTAbBgNVBAoMFE9wZW5TdGFjayBGb3Vu
	ZGF0aW9uMRcwFQYDVQQLDA5JbmZyYXN0cnVjdHVyZTEdMBsGA1UEAwwUenV1bHYz
	Lm9wZW5zdGFjay5vcmcxMjAwBgkqhkiG9w0BCQEWI29wZW5zdGFjay1pbmZyYUBs
	aXN0cy5vcGVuc3RhY2sub3JnMB4XDTE3MDYxNDE3MDM0MVoXDTE4MDYxNDE3MDM0
	MVowgbMxCzAJBgNVBAYTAlVTMQ4wDAYDVQQIDAVUZXhhczEPMA0GA1UEBwwGQXVz
	dGluMR0wGwYDVQQKDBRPcGVuU3RhY2sgRm91bmRhdGlvbjEXMBUGA1UECwwOSW5m
	cmFzdHJ1Y3R1cmUxFzAVBgNVBAMMDmdlYXJtYW4gc2VydmVyMTIwMAYJKoZIhvcN
	AQkBFiNvcGVuc3RhY2staW5mcmFAbGlzdHMub3BlbnN0YWNrLm9yZzCCASIwDQYJ
	KoZIhvcNAQEBBQADggEPADCCAQoCggEBAM5gIcHIidvmE/tRdw9MO+M1XgbPV1+H
	SmHfYR25RHXUC51H3ouxKNb7VDRDmpYJKKqdxaqAyydaEUz4FIoIiqqofOXoqwoX
	KZwV1ysLRvV6L9F1aDD91BAY74Z2BGpUYifNxHO7fGr6GZwxCfBxXq8yNd8DllpV
	s0PH3vmfheLV+tIIuVMTn7Rf5fYqtUDw2PJ6YNixZQwMGBz2vL1k1kSYdJMZdQXv
	XKiU6eWa58fEjWciep3wF990J3LPwYFxc/6qW2x0TkfvKRFStMiOklS0U9udKWut
	OkCkh3zs/dXyOV6kJi0SiM1iVhG/FwjLdpNr/XtkQUEM+Fgq+p8lzA8CAwEAAaN7
	MHkwCQYDVR0TBAIwADAsBglghkgBhvhCAQ0EHxYdT3BlblNTTCBHZW5lcmF0ZWQg
	Q2VydGlmaWNhdGUwHQYDVR0OBBYEFJdLwcoyNW55JeNe5xGcKT8UAeteMB8GA1Ud
	IwQYMBaAFL5FULtP9ZSA4hIDlYCeFBnt5cZOMA0GCSqGSIb3DQEBCwUAA4IBAQA5
	WbLboW21KDfGn3SaP4DhTKydzSYGhn4QDA6ylpRXNw4DD/FV1RPz3YpPP/r809WW
	08x5qaeAf6BpVUM/16uz6cgYkpNMdcvYdFpwetx5nn9wtcE5yceoOJgvXN9A3z9p
	jRduLwHQ7Nw6VR2bsw+1XwDSjc/X3Fx2l2Kz7X7kUVmgoKHX1uyTujeEACIVN2w7
	lH604X/v66c3mRnsD8yyKiE/RDe7wTZPJhE3Tw2vf4RML2q8H0nVv9rINE6qwdjJ
	miB3234z/+n5KJfoR5IT94YNZev0qAtNoaykQ2iETFxGYWqiMrZb2Nb+8FXuCIog
	0MHVQH/l7PvIexMBg8ja
	-----END CERTIFICATE-----
	Signed certificate is in newcert.pem

Installing the Certificates
---------------------------

2 files will have been created, newcert.pem (public key) and newreq.pem (private
key). Be sure to use caution while transporting these files, specifcially
newreq.pem should be added into private hieradata for the specific server and
then deleted from disk.

**NOTE** Be sure to delete newcert.pem and newreq.pem from the top-level
directory once complete. This helps avoid leaking our private keys.

