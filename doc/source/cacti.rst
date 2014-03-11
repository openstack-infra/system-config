:title: Cacti

.. _cacti:

Cacti
######

The `Cacti <http://www.cacti.net/>`_ network graphing tool
is installed on cacti.opencontrail.org.

At a Glance
===========

:Hosts:
  * http://cacti.opencontrail.org
:Puppet:
  * :file:`modules/opencontrail_project/manifests/cacti.pp`
:Projects:
  * http://www.cacti.net
:Bugs:
  * http://bugs.launchpad.net/opencontrail-ci
  * http://www.cacti.net/bugs.php
:Resources:
  * `Cacti Documentation <http://www.cacti.net/documentation.php>`_

Overview
========

Cacti is accessible via the web here:

http://cacti.opencontrail.org/cacti/graph_view.php

New servers are added to our cacti instance by adding the host to the
:file:`modules/opencontrail_project/manifests/cacti.pp` file.
