:title: Mailing Lists

.. _lists:

Mailing Lists
#############

`Mailman <http://www.gnu.org/software/mailman/>`_ is installed on
lists.openstack.org to run OpenStack related mailing lists, as well as
host list archives.

At a Glance
===========

:Hosts:
  * http://lists.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-mailman/tree/
  * :file:`modules/openstack_project/manifests/lists.pp`
:Projects:
  * http://www.gnu.org/software/mailman/
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * https://bugs.launchpad.net/mailman
:Resources:
  * `Mailman Documentation <http://www.gnu.org/software/mailman/docs.html>`_

Adding a List
=============

A list may be added by adding it to the ``openstack-infra/system-config``
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

Scripted Changes to Lists
=========================

This may only be performed with root access to the list server.

Mailman supports running a python code snippet in the context of
individual lists or every list on the system.  The following example
adds an address to the list of banned addresses for every list.  This
has proved useful in the case of attackers abusing the HTTP
subscription interface to subscribe a target's address to multiple
mailing lists.

Banning an Address from All Lists
---------------------------------

Create the file `/usr/lib/mailman/bin/ban.py` with the following
content:

.. code-block:: python

  def ban(m, address):
      try:
          m.Lock()
          if address not in m.ban_list:
              m.ban_list.append(address)
          m.Save()
      finally:
          m.Unlock()

And then run the withlist script as:

.. code-block:: bash

  sudo -u list /usr/lib/mailman/bin/withlist -a -r ban "<address to ban>"

Because the script itself handles locking, do not use the `-l`
argument to withlist.  To run the same script on a single list, use:

.. code-block:: bash

  sudo -u list /usr/lib/mailman/bin/withlist -r ban listname "<address to ban>"
