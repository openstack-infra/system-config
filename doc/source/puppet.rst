Puppet Master
=============

Overview
--------

Puppet agent is a mechanism use to pull puppet manifests and configuration
from a centralized master. This means there is only one place that needs to
hold secure information such as passwords, and only one location for the git
repo holding the modules.

Puppet Master
-------------

The puppet master is setup using a combination of Apache and mod passenger to
ship the data to the clients.

The cron jobs, current configuration files and more can be done with ``puppet
apply`` but first some bootstrapping needs to be done.

First want to install these from puppetlabs' apt repo, but we typically pin to
a specific version, so you'll want to copy in the preferences file from the git
repository. Configuration files for puppet master are stored in a git repo
clone at ``/opt/config/production`` so we'll just do this checkout now and copy
over the preferences file:

.. code-block:: bash

   git clone git://github.com/openstack-infra/config.git /opt/config/production
   cp /opt/config/production/modules/openstack_project/files/00-puppet.pref /etc/apt/preferences.d/

Then we can add the repo and install the packages:

.. code-block:: bash

    echo "deb http://apt.puppetlabs.com precise devel" > /etc/apt/sources.list.d/puppetlabs.list
    apt-get update
    apt-get install puppet puppetmaster-passenger

Finally, install the modules and use ``puppet apply`` to finish configuration:

.. code-block:: bash

   bash /opt/config/production/install_modules.sh
   puppet apply --modulepath='/opt/config/production/modules:/etc/puppet/modules' -e 'include openstack_project::puppetmaster'

Hiera
-----

Hiera is used to maintain secret information on the puppetmaster.

We want to install hiera from puppetlabs' apt repo which was added in the step
above.

.. code-block:: bash

    apt-get install hiera hiera-puppet

Hiera uses a systemwide configuration file in ``/etc/puppet/hiera.yaml`` which
was pulled in during the ``puppet apply`` in the puppetmaser configuration.

This setup supports multiple configuration. The two sets of environments
that OpenStack Infrastructure uses are ``production`` and ``development``.
``production`` is the default is and the environment used when nothing else
is specified. Then the configuration needs to be placed into common.yaml in
``/etc/puppet/hieradata/production`` and ``/etc/puppet/hieradata/development``.
The values are simple key-value pairs in yaml format.

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
