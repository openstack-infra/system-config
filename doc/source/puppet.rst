:title: Puppet Master

.. _puppet-master:

Puppet Master
#############

The puppetmaster server is named puppetmaster for historical reasons - it
no longer runs a puppetmaster process. There is a centralized 'hiera'
database that contains secure information such as passwords. The puppetmaster
server is where the ansible playbooks to run puppet apply on all of the
servers lives, as well as the scripts to create new servers.

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

Puppet Driving Ansible Driving Puppet
-------------------------------------

In OpenStack Infra, there are ansible playbooks that drive the running of
``puppet apply`` on all of the hosts in the inventory. That process first
copies appropriate ``hiera`` data files to each host, and what it is done
it copies back the JSON report of the puppet run and submits it to
``puppetdb``.

The cron jobs, current configuration files and more can be done with ``puppet
apply`` but first some bootstrapping needs to be done.

You want to install these from puppetlabs' apt repo. There is a script in the
root of the system-config repository that will setup and install the
puppet client. After that you must install the ansible playbooks and hiera
config (used to maintain secrets on the puppet master).

Ansible and Puppet 3 can run on Trusty, Precise, and Centos 6.

.. code-block:: bash

   sudo su -
   git clone https://git.openstack.org/openstack-infra/system-config /opt/system-config/production
   bash /opt/system-config/production/install_puppet.sh
   bash /opt/system-config/production/install_modules.sh
   echo $REAL_HOSTNAME > /etc/hostname
   service hostname restart
   puppet apply --modulepath='/opt/system-config/production/modules:/etc/puppet/modules' -e 'include openstack_project::puppetmaster'

Hiera uses a systemwide configuration file in ``/etc/puppet/hiera.yaml``
and this setup supports multiple configurations. The two sets of environments
that OpenStack Infrastructure uses are ``production`` and ``development``.
``production`` is the default is and the environment used when nothing else is
specified.

The hiera configuration is placed placed by puppet apply into common.yaml in
``/etc/puppet/hieradata/production`` and ``/etc/puppet/hieradata/development``.
The values are simple key-value pairs in yaml format. The keys needed are the
keys referenced in your ``site.pp``, their values are typically obvious
(strings, lists of strings). ``/etc/puppet/hieradata/`` and below should be
owned by ``puppet:puppet`` and have mode ``0711``.

Below the ``hieradata`` directory, there should be a ``common.yaml`` file where
settings that should be available to all servers in the infrastrucutre go,
and then two directories full of files. The first is ``fqdn`` which should
contain a yaml file for every server in the infrastructure named
``${fqdn_of_server}.yaml``. That file has secrets that are only for that
server. Additionally, some servers can have a ``$group`` defined in
``manifests/site.pp``. There can be a correspondingly named yaml file in the
``group`` directory that contains secrets to be made available to each
server in the group.

All of the actual yaml files should have mode 0600.

Adding a node
-------------

For adding a new node to your puppet master, you can either use the
``/opt/system-config/production/launch/launch-node.py`` script
(see :file:`launch/README` for full details) or bootstrap puppet manually.

For manual bootstrap, you need to run on the new server connecting
(for example, review.openstack.org) to the puppet master:

.. code-block:: bash

   sudo su -
   wget https://git.openstack.org/cgit/openstack-infra/system-config/plain/install_puppet.sh
   bash -x install_puppet.sh

Running Puppet on Nodes
-----------------------

In OpenStack's Infrastructure, puppet runs are triggered from a cronjob
running on the puppetmaster which in turn runs a single run of puppet agent on
each host we know about.

The entry point for this process is ``/opt/system-config/production/run_all.sh``

There are a set of nodes, which are configured in puppet as "override" nodes,
which are run in sequence before the rest of the nodes are run in parallel.
At the moment, this allows creation of git repos on the git slaves before
creation of the master repos on the gerrit server.

Disabling Puppet on Nodes
-------------------------

TODO: mordred - we do not have an answer for this yet

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
