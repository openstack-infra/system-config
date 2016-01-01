:title: refstack

.. _refstack:

Refstack
########

Refstack is a public facing test reporting site supporting the efforts of
the DefCore committee to identify widely deployed capabilities and also to
verify the test results against the established capability specification.


At a Glance
===========

:Hosts:
  * http://refstack.openstack.org/
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-refstack/
:Projects:
  * https://git.openstack.org/cgit/openstack/refstack/
:Bugs:
  * https://bugs.launchpad.net/refstack

Overview
========

There are three major components in the Refstack server:

Refstack-UI
-----------

Refstack-UI is a web interface for interacting with data collected with
the API server and client.

Refstack-API
------------

Refstack-API server is a central repository for the collection of
interoperability test results. It also provides APIs to facilitate the
uploading/retrieval of test data.  Users can use the refstack-client tool
to anonymously upload their data to the refstack.openstack.org site.

MySQL database
--------------

This is the database to host the user uploaded test results data.

More information about the Refstack project can be found at
 https://wiki.openstack.org/wiki/RefStack
