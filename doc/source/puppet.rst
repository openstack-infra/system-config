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
  * puppetmaster.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/puppetmaster.pp`
:Projects:
  * https://puppetlabs.com/
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * https://tickets.puppetlabs.com/
:Resources:
  * `Puppet Language Reference <https://docs.puppetlabs.com/references/latest/type.html>`_

Puppet Master
-------------

The puppet master is setup using a combination of Apache and mod passenger to
ship the data to the clients.

The cron jobs, current configuration files and more can be done with ``puppet
apply`` but first some bootstrapping needs to be done.

You want to install these from puppetlabs' apt repo. There is a script in the
root of the system-config repository that will setup and install the
puppet client. After that you must install the puppetmaster and hiera (used to
maintain secrets on the puppet master).

Puppet 3 masters can run on Trusty, Precise, and Centos 6.

.. code-block:: bash

   sudo su -
   git clone https://git.openstack.org/openstack-infra/system-config /opt/system-config/production
   /opt/system-config/production/install_puppet.sh
   apt-get install puppetmaster-passenger hiera hiera-puppet

Finally, install the modules, fix your hostname and use ``puppet apply`` to
finish configuration:

.. code-block:: bash

   bash /opt/system-config/production/install_modules.sh
   echo $REAL_HOSTNAME > /etc/hostname
   service hostname restart
   puppet apply --modulepath='/opt/system-config/production/modules:/etc/puppet/modules' -e 'include openstack_project::puppetmaster'

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

On the new server connecting (for example, review.openstack.org) to
the puppet master:

.. code-block:: bash

  sudo apt-get install puppet

The node then needs to be configured to set a fixed hostname and the
hostname of the puppet master with the following additions to
``/etc/puppet/puppet.conf``:

.. code-block:: ini

   [main]
   server=puppetmaster.openstack.org
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

Once the cert is signed, the puppet running orchestration will pick up
the node and run puppet on it as needed.

Running Puppet on Nodes
-----------------------

In OpenStack's Infrastructure, puppet runs are triggered from a cronjob
running on the puppetmaster which in turn runs a single run of puppet on
each host we know about. We do not use the daemon mode of puppet agent
because it experiences random hangs, and also does not allow us to control
sequencing in any meaningful way.

The entry point for this process is ``/opt/system-config/production/run_all.sh``

There are a set of nodes, which are configured in puppet as "override" nodes,
which are run in sequence before the rest of the nodes are run in parallel.
At the moment, this allows creation of git repos on the git slaves before
creation of the master repos on the gerrit server.

Disabling Puppet on Nodes
-------------------------

In the case of needing to disable the running of puppet on a node, it's a
simple matter of disabling the agent:

.. code-block:: bash

  sudo puppet agent --disable

This will prevent any subsequent runs of the agent, including ones triggered
globally by the run_all script. If, as an admin, you need to run puppet on
a node where it has been disabled, you need to specify an alternate disable
lock file which will allow your local run of puppet without allowing the
globally orchestrated runs to occur:

.. code-block:: bash

  sudo puppet agent --test --agent_disabled_lockfile=/tmp/alt-lock-file


Important Notes
---------------

#. Make sure the site manifest **does not** include the puppet cron job, this
   conflicts with puppet master and can cause issues.  The initial puppet run
   that create users should be done using the puppet agent configuration above.

#. If you do not see the cert in the master's cert list the agent's
   ``/var/log/syslog`` should have an entry showing you why.
