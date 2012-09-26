:title: Jenkins Configuration

Jenkins
#######

Overview
********

Jenkins is a Continuous Integration system and the central control
system for the orchestration of both pre-merge testing and post-merge
actions such as packaging and publishing of documentation.

The overall design that Jenkins is a key part of implementing is that
all code should be reviewed and tested before being merged in to trunk,
and that as many tasks around review, testing, merging and release that
can be automated should be.

Jenkis is essentially a job queing system, and everything that is done
through Jenkins can be thought of as having a few discreet components:

* Triggers - What causes a job to be run
* Location - Where do we run a job
* Steps - What actions are taken when the job runs
* Results - What is the outcome of the job

The OpenStack Jenkins can be found at http://jenkins.openstack.org

OpenStack uses :doc:`gerrit` to manage code reviews, which in turns calls
Jenkins to test those reviews.

Authorization
*************

Jenkins is set up to use OpenID in a Single Sign On mode with Launchpad.
This means that all of the user and group information is managed via
Launchpad users and teams. In the Jenkins Security Matrix, a Launchpad team
name can be specified and any members of that team will be granted those
permissions. However, because of the way the information is processed, a
user will need to re-log in upon changing either team membership on
Launchpad, or changing that team's authorization in Jenkins for the new
privileges to take effect.

Integration Testing
*******************

TODO: How others can get involved in testing and integrating with
OpenStack Jenkins.

Rackspace Bare-Metal Testing Cluster
====================================

The CI team mantains a cluster of machines supplied by Rackspace to
perform bare-metal deployment and testing of OpenStack as a whole.
This installation is intended as a reference implementation of just
one of many possible testing platforms, all of which can be integrated
with the OpenStack Jenkins system.  This is a cluster of several
physical machines meaning the test environment has access to all of
the native processor features, and real-world networking, including
tagged VLANs.

Each time the trunk repo is updated, a Jenkins job will deploy an
OpenStack cluster using devstack and then run the openstack-test-rax
test suite against the cluster.

Deployment and Testing Process
------------------------------

The cluster deployment is divided into two phases: base operating
system installation, and OpenStack installation.  Because the
operating system install takes considerable time (15 to 30 minutes),
has external network resource dependencies (the distribution mirror),
and has no bearing on the outcome of the OpenStack tests themselves,
the process used here effectively snapshots the machines immediately
after the base OS install and before OpenStack is installed.  LVM
snapshots and kexec are used to immediately return the cluster to a
newly installed state without incurring the additional time it would
take to install from scratch.  The Jenkins testing job invokes the
process starting at :ref:`rax_openstack_install`.

Installation Server Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The CI team runs the Ubuntu Orchestra server (based on cobbler) on our
Jenkins slave node to manage the OS installation on the test machines.
The configuration for the Orchestra server is kept in the CI team's
puppet modules.  If you want to set up your own system, Orchestra is
not required, any system capable of performing the following steps is
suitable.  However, if you want to stand up a test system as quickly
and simply as possible, you may find it easiest to base your system on
the one the CI team uses.  You may use the puppet modules yourself, or
follow the instructions below.

The CI team's Orchestra configuration module is at:

https://github.com/openstack/openstack-ci-puppet/tree/master/modules/orchestra

Install Orchestra
"""""""""""""""""

Install Ubuntu 11.10 (Oneiric) and Orchestra::

  sudo apt-get install ubuntu-orchestra-server ipmitool

The install process will prompt you to enter a password for Cobbler.
Have one ready and keep it in a safe place.  The procedure here will
not use it, but if you later want to use the Cobbler web interface,
you will need it.

Configure Orchestra
"""""""""""""""""""

Install the following files on the Orchestra server so that it deploys
machines with our LVM/kexec test framework.

We update the dnsmasq.conf cobbler template to add
"dhcp-ignore=tag:!known", and some site-specific network
configuration::

  wget https://raw.github.com/openstack/openstack-ci-puppet/master/modules/orchestra/files/dnsmasq.template \
  -O /etc/cobbler/dnsmasq.template

Our servers need a kernel module blacklisted in order to boot
correctly.  If you don't need to blacklist any modules, you should
either create an empty file here, or remove the reference to this file
from the preseed file later::

  wget https://raw.github.com/openstack/openstack-ci-puppet/master/modules/orchestra/files/openstack_module_blacklist \
  -O /var/lib/cobbler/snippets/openstack_module_blacklist

This cobbler snippet uses cloud-init to set up the LVM/kexec
environment and configures TCP syslogging to the installation
server/Jenkins slave::

  wget https://raw.github.com/openstack/openstack-ci-puppet/master/modules/orchestra/files/openstack_cloud_init \
  -O /var/lib/cobbler/snippets/openstack_cloud_init

This snippet holds the mysql root password that will be configured at
install time.  It's currently a static string, but you could
dynamically write this file, or simply replace it with something more
secure::

  wget https://raw.github.com/openstack/openstack-ci-puppet/master/modules/orchestra/files/openstack_mysql_password \
  -O /var/lib/cobbler/snippets/openstack_mysql_password

This preseed file manages the OS install on the test nodes.  It
includes the snippets installed above::

  wget https://raw.github.com/openstack/openstack-ci-puppet/master/modules/orchestra/files/openstack-test.preseed \
  -O /var/lib/cobbler/kickstarts/openstack-test.preseed

The following sudoers configuration is needed to allow Jenkins to
control cobbler, remove syslog files from the test hosts before
starting new tests, and restart rsyslog::

  wget https://raw.github.com/openstack/openstack-ci-puppet/master/modules/orchestra/files/orchestra-jenkins-sudoers -O /etc/sudoers.d/orchestra-jenkins

Replace the Orchestra rsyslog config file with a simpler one that logs
all information from remote hosts in one file per host::

  wget https://raw.github.com/openstack/openstack-ci-puppet/master/modules/orchestra/files/99-orchestra.conf -O /etc/rsyslog.d/99-orchestra.conf

Make sure the syslog directories exist and restart rsyslog::

  mkdir -p /var/log/orchestra/rsyslog/
  chown -R syslog.syslog /var/log/orchestra/
  restart rsyslog

Add an "OpenStack Test" system profile to cobbler that uses the
preseed file above::

  cobbler profile add \
  --name=natty-x86_64-ostest \
  --parent=natty-x86_64 \
  --kickstart=/var/lib/cobbler/kickstarts/openstack-test.preseed \
  --kopts="priority=critical locale=en_US"

Add each of your systems to cobbler with a command similar to this
(you may need different kernel options)::

  cobbler system add \
  --name=baremetal1 \
  --hostname=baremetal1 \
  --profile=natty-x86_64-ostest \
  --mac=00:11:22:33:44:55 \
  --power-type=ipmitool \
  --power-user=IPMI_USERNAME \
  --power-pass=IPMI_PASS \
  --power-address=IPMI_IP_ADDR \
  --ip-address=SYSTEM_IP_ADDRESS \
  --subnet=SYSTEM_SUBNET \
  --kopts="netcfg/choose_interface=auto netcfg/dhcp_timeout=60 auto=true priority=critical"

When complete, have cobbler write out its configuration files::

  cobbler sync

Set Up Jenkins Jobs
"""""""""""""""""""

We have Jenkins jobs to handle all of the tasks after the initial
Orchestra configuration so that we can easily run them at any time.
This includes the OS installation on the test nodes, even though we
don't run that often because the state is preserved in an LVM
snapshot, we may want to change the configuration used and make a new
snapshot.  In that case we just need to trigger the Jenkins job again.

The Jenkins job that kicks off the operating system installation calls
the "baremetal-os-install.sh" script from the openstack-ci repo:

  https://github.com/openstack/openstack-ci/blob/master/slave_scripts/baremetal-os-install.sh

That script instructs cobbler to install the OS on each of the test
nodes.

To speed up the devstack installation and avoid excessive traffic to
the pypi server, we build a PIP package cache on the installation
server.  That is also an infrequent task that we configure as a
jenkins job.  That calls:

  https://github.com/openstack/openstack-ci/blob/master/slave_scripts/update-pip-cache.sh

That builds a PIP package cache that the test script later copies to
the test servers for use by devstack.

Run those two jobs, and once complete, the test nodes are ready to go.

This is the end of the operating system installation, and the system
is currently in the pristine state that will be used by the test
procedure (which is stored in the LVM volume "orig_root").

.. _rax_openstack_install:

OpenStack Installation
~~~~~~~~~~~~~~~~~~~~~~

When the deployment and integration test job runs, it does the
following, each time starting from the pristine state arrived at the
end of the previous section.

Reset the Test Nodes
""""""""""""""""""""

The Jenkins deployment and test job first runs the deployment script:

  https://github.com/openstack/openstack-ci/blob/master/slave_scripts/baremetal-deploy.sh

Which invokes the following script on each host to reset it to the
pristine state:

  https://github.com/openstack/openstack-ci/blob/master/slave_scripts/lvm-kexec-reset.sh

Because kexec is in use, resetting the environment and rebooting into
the pristine state takes only about 3 seconds.

The deployment script then removes the syslog files from the previous
run and restarts rsyslog to re-open them.  Once the first test host
finishes booting and brings up its network, OpenStack installation
starts.

Run devstack on the Test Nodes
""""""""""""""""""""""""""""""

Devstack's build_bm_multi script is run, which invokes devstack on
each of the test nodes.  First on the "head" node which runs all of
the OpenStack services for the remaining "compute" nodes.

Run Test Suite
""""""""""""""

Once devstack is complete, the test suite is run.  All logs from the
test nodes should be sent via syslog to the Jenkins slave, and at the
end of the test, the logs are archived with the Job for developers to
inspect in case of problems.

Cluster Configuration
---------------------

Here are the configuration parameters of the CI team's test cluster.
The cluster is currently divided into three mini-clusters so that
independent Jenkins jobs can run in parallel on the different
clusters.

VLANs
~~~~~

+----+--------------------------------+
|VLAN| Description                    |
+====+================================+
|90  | Native VLAN                    |
+----+--------------------------------+
|91  | Internal cluster communication |
|    | network: 192.168.91.0/24       |
+----+--------------------------------+
|92  | Public Internet (fake)         |
|    | network: 192.168.92.0/24       |
+----+--------------------------------+

Servers
~~~~~~~
The servers are located on the Rackspace network, only accessible via
VPN.

+-----------+--------------+---------------+
| Server    | Primary IP   | Management IP |
+===========+==============+===============+
|deploy-rax | 10.14.247.36 | 10.14.247.46  |
+-----------+--------------+---------------+
|baremetal1 | 10.14.247.37 | 10.14.247.47  |
+-----------+--------------+---------------+
|baremetal2 | 10.14.247.38 | 10.14.247.48  |
+-----------+--------------+---------------+
|baremetal3 | 10.14.247.39 | 10.14.247.49  |
+-----------+--------------+---------------+
|baremetal4 | 10.14.247.40 | 10.14.247.50  |
+-----------+--------------+---------------+
|baremetal5 | 10.14.247.41 | 10.14.247.51  |
+-----------+--------------+---------------+
|baremetal6 | 10.14.247.42 | 10.14.247.52  |
+-----------+--------------+---------------+
|baremetal7 | 10.14.247.43 | 10.14.247.53  |
+-----------+--------------+---------------+
|baremetal8 | 10.14.247.44 | 10.14.247.54  |
+-----------+--------------+---------------+
|baremetal9 | 10.14.247.45 | 10.14.247.55  |
+-----------+--------------+---------------+

deploy-rax
  The deployment server and Jenkins slave.  It deploys the servers
  using Orchestra and Devstack, and runs the test framework.  It
  should not run any OpenStack components, but we can install
  libraries or anything else needed to run tests.

baremetal1, baremetal4, baremetal7
  Configured as "head" nodes to run nova, mysql, and glance.  Each one
  is the head node of a three node cluster including the two compute
  nodes following it

baremetal2-3, baremtal5-6, baremetal8-9
  Configured as compute nodes for each of the three mini-clusters.

