:title: Mailing Lists

Mailing Lists
#############

`Mailman <http://www.gnu.org/software/mailman/>`_ is installed on
lists.openstack.org to run OpenStack related mailing lists, as well as
host list archives.

Adding a List
=============

A list may be added by adding it to the ``openstack-infra/config``
repository in ``modules/openstack_project/manifests/lists.pp``.  For
example:

.. code-block:: ruby

  maillist { 'openstack-foo':
    ensure      => present,
    admin       => 'admin@example.com',
    password    => $listpassword,
    description => 'Discussion of OpenStack Foo',
    webserver   => $listdomain,
    mailserver  => $listdomain,
  }

