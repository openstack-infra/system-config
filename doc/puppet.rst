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

Since we rely on upstream, puppetlabs, for packages we need to add their GPG
key and repository information:

.. code-block:: bash
  wget http://apt.puppetlabs.com/pubkey.gpg -O - | sudo apt-key add -
  sudo apt-add-repository "deb http://apt.puppetlabs.com precise main"
  sudo apt-get update

Next we need to install the puppet packages:

.. code-block:: bash
  sudo apt-get install puppet puppetmaster-passenger

Files for puppet master are stored in a git repo clone at
``/opt/openstack-ci-puppet``.  We have a ``root`` cron job that
automatically populates these from our puppet git repository as follows:

.. code-block:: bash

  \*/15 * * * * sleep $((RANDOM\%600)) && cd /opt/openstack-ci-puppet && /usr/bin/git pull -q

The ``/etc/puppet/puppet.conf`` file then needs updating to point to the
manifest and modules as follows:

.. code-block:: ini

   [master]
   # These are needed when the puppetmaster is run by passenger
   # and can safely be removed if webrick is used.
   ssl_client_header = SSL_CLIENT_S_DN
   ssl_client_verify_header = SSL_CLIENT_VERIFY
   manifestdir=/opt/openstack-ci-puppet/manifests
   modulepath=/opt/openstack-ci-puppet/modules
   manifest=$manifestdir/site.pp

Hiera
-----

Hiera is used to maintain secret information on the puppetmaster.

We want to install hiera from puppetlabs' apt repo, but we don't want to get
on the puppet upgrade train - so the process is as follows:

.. code-block:: bash

  echo "deb http://apt.puppetlabs.com precise devel" | sudo tee /etc/apt/sources.list.d/puppetlabs.list
  sudo apt-get update
  sudo apt-get install hiera hiera-puppet
  sudo rm /etc/apt/sources.list.d/puppetlabs.list
  sudo apt-get update

Hiera uses a systemwide configuration file in ``/etc/puppet/hiera.yaml``
which tells is where to find subsequent configuration files.

.. code-block:: yaml

    ---
    :hierarchy:
      - %{operatingsystem}
      - common
    :backends:
      - yaml
    :yaml:
      :datadir: '/etc/puppet/hieradata/%{environment}'

This setup supports multiple configuration. The two sets of environments
that OpenStack CI users are ``production`` and ``development``. ``production``
is the default is and the environment used when nothing else is specified.
Then the configuration needs to be placed into common.yaml in
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
