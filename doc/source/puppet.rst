:title: Puppet Master

.. _puppet-master:

Puppet Master
#############

Puppet agent is a mechanism use to pull puppet manifests and configuration
from a centralized master. This means there is only one place that needs to
hold secure information such as passwords, and only one location for the git
repo holding the modules.

At a Glance
===========

:Hosts:
  * ci-puppetmaster.openstack.org
  * http://puppet-dashboard.openstack.org:3000/
:Puppet:
  * :file:`modules/openstack_project/manifests/puppetmaster.pp`
:Projects:
  * https://puppetlabs.com/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * http://projects.puppetlabs.com/
:Resources:
  * `Puppet Language Reference <http://docs.puppetlabs.com/references/2.7.latest/type.html>`_

Puppet Master
-------------

The puppet master is setup using a combination of Apache and mod passenger to
ship the data to the clients.

The cron jobs, current configuration files and more can be done with ``puppet
apply`` but first some bootstrapping needs to be done.

First want to install these from puppetlabs' apt repo. We have not yet migrated
to puppet 3, so we pin puppet to 2.x. There is a script in the root of the
config repository that will setup appropriate pinning and install the puppet
client. After that installing the puppetmaster and hiera (used to maintain
secrets on the puppet master).

Please note: Fedora F19 and Ubuntu Raring and above cannot successfully run an
OpenStack-CI puppetmaster due to new Ruby and older Puppet not being
compatible, so be sure to use an older release - e.g. Ubuntu Precise.

.. code-block:: bash

   sudo su -
   git clone https://git.openstack.org/openstack-infra/config /opt/config/production
   /opt/config/production/install_puppet.sh
   apt-get install puppetmaster-passenger hiera hiera-puppet

Finally, install the modules, fix your hostname and use ``puppet apply`` to
finish configuration:

.. code-block:: bash

   bash /opt/config/production/install_modules.sh
   echo $REAL_HOSTNAME > /etc/hostname
   service hostname restart
   puppet apply --modulepath='/opt/config/production/modules:/etc/puppet/modules' -e 'include openstack_project::puppetmaster'

Note: Hiera uses a systemwide configuration file in ``/etc/puppet/hiera.yaml``
and this setup supports multiple configurations. The two sets of environments
that OpenStack Infrastructure uses are ``production`` and ``development``.
``production`` is the default is and the environment used when nothing else is
specified. Then the configuration needs to be placed into common.yaml in
``/etc/puppet/hieradata/production`` and ``/etc/puppet/hieradata/development``.
The values are simple key-value pairs in yaml format. The keys needed are the
keys referenced in your ``site.pp``, their values are typically obvious
(strings, lists of strings). ``/etc/puppet/hieradata/`` and below should be
owned by ``puppet:puppet`` and have mode ``0711``. The actual ``common.yaml``
file should have mode 0600.

Adding a node
-------------

On the new server connecting (for example, review.openstack.org) to the puppet master:

.. code-block:: bash

  sudo apt-get install puppet

Then edit the ``/etc/default/puppet`` file to change the start variable:

.. code-block:: ini

  # Start puppet on boot?
  START=yes

The node then needs to be configured to set a fixed hostname and the hostname
of the puppet master with the following additions to ``/etc/puppet/puppet.conf``:

.. code-block:: ini

   [main]
   server=ci-puppetmaster.openstack.org
   certname=review.openstack.org

The cert signing process needs to be started with:

.. code-block:: bash

  sudo puppet agent --test

This will make a request to the puppet master to have its SSL cert signed.
On the puppet master:

.. code-block:: bash

  sudo puppet cert list

You should get a list of entries similar to the one below::

  review.openstack.org  (44:18:BB:DF:08:50:62:70:17:07:82:1F:D5:70:0E:BF)

If you see the new node there you can sign its cert on the puppet master with:

.. code-block:: bash

  sudo puppet cert sign review.openstack.org

Finally on the puppet agent you need to start the agent daemon:

.. code-block:: bash

   sudo service puppet start

Now that it is signed the puppet agent will execute any instructions for its
node on the next run (default is every 30 minutes).  You can trigger this
earlier by restarting the puppet service on the agent node.

Important Notes
---------------

#. Make sure the site manifest **does not** include the puppet cron job, this
   conflicts with puppet master and can cause issues.  The initial puppet run
   that create users should be done using the puppet agent configuration above.

#. If you do not see the cert in the master's cert list the agent's
   ``/var/log/syslog`` should have an entry showing you why.
