:title: Mailing Lists

.. _lists:

Mailing Lists
#############

`Mailman <http://www.gnu.org/software/mailman/>`_ is installed on
lists.opencontrail.org to run OpenContrail related mailing lists, as well as
host list archives.

At a Glance
===========

:Hosts:
  * http://lists.opencontrail.org
:Puppet:
  * :file:`modules/mailman`
  * :file:`modules/opencontrail_project/manifests/lists.pp`
:Projects:
  * http://www.gnu.org/software/mailman/
:Bugs:
  * http://bugs.launchpad.net/opencontrail-ci
  * https://bugs.launchpad.net/mailman
:Resources:
  * `Mailman Documentation <http://www.gnu.org/software/mailman/docs.html>`_

Adding a List
=============

A list may be added by adding it to the ``opencontrail-infra/config``
repository in ``modules/opencontrail_project/manifests/lists.pp``.  For
example:

.. code-block:: ruby

  maillist { 'opencontrail-foo':
    ensure      => present,
    admin       => 'admin@example.com',
    password    => $listpassword,
    description => 'Discussion of OpenContrail Foo',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

