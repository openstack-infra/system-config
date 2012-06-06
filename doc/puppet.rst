Puppet Master
=============

Overview
--------

Instead of using a cron job, StackForge uses a puppet master to host the puppet
manifests and modules.  The other nodes then connect to this as puppet agents
to get their configuration.

Puppet Master
-------------

The puppet master is setup using a combination of Apache and mod passenger to
ship the data to the clients.  To install this:

.. code-block:: bash

  sudo apt-get install puppet puppetmaster-passenger

Files for puppet master are stored in a git repo clone at
``/opt/openstack-ci-puppet``.  In StackForge we have a ``root`` cron job that
automatically populates these from our puppet git repository as follows:

.. code-block:: bash

  */15 * * * * sleep $((RANDOM\%600)) && cd /opt/openstack-ci-puppet && /usr/bin/git pull -q

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
   manifest=$manifestdir/stackforge.pp


Adding a node
-------------

On the new server connecting to the puppet master:

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
   server=puppet.stackforge.org
   certname=review.stackforge.org

The cert signing process needs to be started with:

.. code-block:: bash

  sudo puppet agent --test

This will make a request to the puppet master to have its SSL cert signed.
On the puppet master:

.. code-block:: bash

  sudo puppet cert list

You should get a list of entries similar to the one below::

  review.stackforge.org  (44:18:BB:DF:08:50:62:70:17:07:82:1F:D5:70:0E:BF)

If you see the new node there you can sign its cert on the puppet master with:

.. code-block:: bash

  sudo puppet cert sign review.stackforge.org

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
