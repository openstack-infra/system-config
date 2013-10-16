:title: Nodepool

.. _nodepool:

Nodepool
########

Nodepool is a service used by the OpenStack CI team to deploy and manage a pool
of devstack images on a cloud server for use in OpenStack project testing.

At a Glance
===========

:Hosts:
  * nodepool.openstack.org
:Puppet:
  * :file:`modules/nodepool/`
  * :file:`modules/openstack_project/manifests/dev_slave_template.pp`
:Configuration:
  * :file:`modules/openstack_project/templates/nodepool/nodepool.yaml.erb`
  * :file:`modules/openstack_project/files/nodepool/scripts/`
:Projects:
  * https://git.openstack.org/openstack-infra/nodepool
:Bugs:
  * http://bugs.launchpad.net/openstack-ci

Overview
========

Once per day, for every image type (and provider) configured by nodepool, a new
image with cached data for use by devstack.  Nodepool spins up new instances
and tears down old as tests are queued up and completed, always maintaining a
consistant number of available instances for tests up to the set limits of the
CI infrastructure.

Developer Setup
===============

If you'd like to work with nodepool to test process, you can set up a local
version and hook it into your cloud.

It his highly recommended that you do this in a virtualized environment.

Install nodepool
----------------

First, you need several packages installed:

.. code-block:: bash

  sudo apt-get install git mysql-server libmysqlclient-dev g++ python-dev libzmq-dev

And if you wish to apply changes that are currently under review:

.. code-block:: bash

  sudo pip install git-review

Now you will want to clone and install nodepool:

.. code-block:: bash

  mkdir src
  cd ~/src
  git clone git://git.openstack.org/openstack-infra/config
  git clone git://git.openstack.org/openstack-infra/nodepool
  cd nodepool
  git review -x XXXXX
  sudo pip install -U -r requirements.txt
  sudo pip install -e .

Note: In the "git review" line, that is where you'd specify any patches under
review that you wish to apply to your nodepool test instance.

Configure MySQL
---------------

.. code-block:: mysql

  mysql -u root
  create database nodepool;
  GRANT ALL ON nodepool.* TO 'nodepool'@'localhost';
  flush privileges;

Create a nodepool.yaml File
---------------------------

The nodepool.yaml file should contain the following (using shell variable syntax
for things you should replace with real values)::

  script-dir:
    $HOME/src/config/modules/openstack_project/files/nodepool/scripts
    dburi: 'mysql://nodepool@localhost/nodepool'

  cron:
    cleanup: '*/5 * * * *'
    check: '*/15 * * * *'
    update-image: '14 2 * * *'

  zmq-publishers:
    - tcp://localhost:8888

  providers:
    - name: tripleo-test-cloud
      service-type: 'compute'
      service-name: 'nova'
      username: '$OS_USERNAME'
      password: '$OS_PASSWORD'
      project-id: '$OS_PROJECT_ID'
      auth-url: '$CLOUD_ENDPOINT'
      boot-timeout: 120
      max-servers: 2
      images:
        - name: tripleo-precise
          base-image: 'Ubuntu Precise 12.04 LTS Server 64-bit'
          min-ram: 8192
          setup: prepare_node_tripleo.sh
          username: jenkins
          private-key: $HOME/.ssh/id_rsa

  targets:
    - name: fake-jenkins
      jenkins:
        url: https://localhost
        user: fake
        apikey: fake
      images:
        - name: tripleo-precise
          min-ready: 2
          providers:
            - name: tripleo-test-cloud

Start nodepool
--------------

In a different shell, start nodepool::

  nodepoold -d -c $HOME/src/nodepool/nodepool.yaml

By default with this command, all logging will go to stdout.

