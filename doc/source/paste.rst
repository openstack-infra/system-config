:title: Paste

.. _paste:

Paste
#####

Paste servers are an easy way to share long-form content such as
configuration files or log data with others over short-form
communication protocols such as IRC.  OpenStack runs the "lodgeit"
paste software.

At a Glance
===========

:Hosts:
  * http://paste.openstack.org
:Puppet:
  * :file:`modules/lodgeit`
  * :file:`modules/openstack_project/manifests/paste.pp`
:Projects:
  * http://github.com/openstack-infra/lodgeit
  * https://bitbucket.org/dcolish/lodgeit-main
  * http://www.pocoo.org/projects/lodgeit/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci

Overview
========

For OpenStack we use `a fork
<https://github.com/openstack-infra/lodgeit>`_ of lodgeit which is
based on one with bugfixes maintained by `dcolish
<https://bitbucket.org/dcolish/lodgeit-main>`_ but adds back missing
anti-spam features required by Openstack.

Puppet configures lodgeit to use MySQL as a database backend, apache
as a front-end proxy.

The lodgeit module takes a MySQL hostname and password as an input, and
assumes that those databases exist and are managed.
