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

  sudo apt-get install puppet puppetmaster puppetmaster-passenger

Note that this may break the first time round due to not-so-perfect packaging
involved.  You will also need to stop the puppetmaster service and edit the
``/etc/defaults/puppetmaster`` file to change ``START=no``.  Puppetmaster needs
to run first because it creates the SSL CA used to sign puppet agents (the
passenger service does not do this).

This should then allow you to start ``apache2`` which in turn will automatically
manage the puppet master.

Files for puppet master are stored in ``/etc/puppet`` with the subdirectories
``manifests`` and ``modules`` being the important ones.  In StackForge we have
a ``root`` cron job that automatically populates these from our puppet git
repository as follows:

.. code-block:: bash

  */15 * * * * sleep $((RANDOM\%600)) && cd /srv/openstack-ci-puppet && /usr/bin/git pull -q  && cp /srv/openstack-ci-puppet/manifests/users.pp /etc/puppet/manifests/ && cp /srv/openstack-ci-puppet/manifests/stackforge.pp /etc/puppet/manifests/site.pp && cp -a /srv/openstack-ci-puppet/modules/ /etc/puppet/

Adding a node
-------------

On the new server connecting to the puppet master:

.. code-block:: bash

  sudo apt-get install puppet

Then edit the ``/etc/default/puppet`` file to look like this:

.. code-block:: ini

  # Defaults for puppet - sourced by /etc/init.d/puppet

  # Start puppet on boot?
  START=yes

  # Startup options
  DAEMON_OPTS="--server puppet.stackforge.org"

You can then start the puppet agent with:

.. code-block:: bash

  sudo service puppet start

Once the node has started it will make a request to the puppet master to have
its SSL cert signed.  On the puppet master:

.. code-block:: bash

  sudo puppet cert list

You should get a list of entries similar to the one below::

  review.novalocal       (44:18:BB:DF:08:50:62:70:17:07:82:1F:D5:70:0E:BF)

If you see the new node there you can sign its cert on the puppet master with:

.. code-block:: bash

  sudo puppet cert sign review.novalocal

Now that it is signed the puppet agent will execute any instructions for its
node on the next run (default is every 30 minutes).  You can trigger this
earlier by restarting the puppet service on the new node.

Important Notes
---------------

#. The hostname of the nodes **must** match the the forward looking for the DNS.
   For example the server pointed to with the DNS entry
   ``jenkins.stackforge.org`` must have the hostname ``jenkins.stackforge.org``
   otherwise the SSL signing or standard run will fail.

#. Make sure the site manifest **does not** include the puppet cron job, this
   conflicts with puppet master and can cause issues.  The initial puppet run
   that create users should be done using the puppet agent configuration above.
