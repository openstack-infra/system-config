:title: Jenkins

.. _jenkins:

Jenkins
#######

Jenkins is a Continuous Integration system that runs tests and
automates some parts of project operations.  It is controlled for the
most part by :ref:`zuul` which determines what jobs are run when.

At a Glance
===========

:Hosts:
  * http://jenkins.openstack.org
  * http://jenkins-dev.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/
  * :file:`modules/openstack_project/manifests/jenkins.pp`
  * :file:`modules/openstack_project/manifests/jenkins_dev.pp`
:Configuration:
  * :config:`jenkins/jobs`
:Projects:
  * http://jenkins-ci.org/
  * :ref:`zuul`
  * :ref:`jjb`
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * https://wiki.jenkins-ci.org/display/JENKINS/Issue+Tracking
:Resources:
  * :ref:`zuul`
  * :ref:`jjb`

Overview
========

A large number and variety of jobs are defined in Jenkins.  The
configuration of all of those jobs is stored in git in the
openstack-infra/project-config repository.  They are defined in YAML
files that are read by :ref:`jjb` which configures the actual jobs in
Jenkins.

Anyone may submit a change to the openstack-infra/project-config
repository that defines a new job or alters an existing job by editing
the appropriate YAML files.  See :ref:`jjb` for more information.

Because of the large number of builds that Jenkins executes, the
OpenStack project favors the following approach in configuring Jenkins
jobs:

  * Minimal use of plugins: the more post-processing work that Jenkins
    needs to perform on a job, the more likely we are to run into
    compatibility problems among plugins, and contention for shared
    resources on the Jenkins master.  A number of popular plugins
    will cause all builds of a job to be serialized even if the jobs
    otherwise run in parallel.
  * Minimal build history: Jenkins stores build history in individual
    XML files on disk, and accessing a large build history can cause
    the Jenkins master to be unresponsive for a significant time while
    loading them.  It also increases memory usage.  Instead, we
    generally keep no more than a day's worth of builds.
  * Move artifacts off of Jenkins: Jenkins is not efficient at serving
    static information such as build artifacts (e.g., tarballs) or
    logs.  Instead, we copy them to a static webserver which is far
    more efficient.

Authorization
=============

Jenkins is set up to use OpenID in a Single Sign On mode with Launchpad.
This means that all of the user and group information is managed via
Launchpad users and teams. In the Jenkins Security Matrix, a Launchpad team
name can be specified and any members of that team will be granted those
permissions. However, because of the way the information is processed, a
user will need to re-log in upon changing either team membership on
Launchpad, or changing that team's authorization in Jenkins for the new
privileges to take effect.

Devstack Gate
=============

OpenStack integration testing is performed by the devstack gate test
framework. This framework runs the devstack exercises and Tempest
smoketests against a devstack install on single use cloud servers. The
devstack gate source can be found on `git.openstack.org
<https://git.openstack.org/cgit/openstack-infra/devstack-gate>`_ and the `Readme
<https://git.openstack.org/cgit/openstack-infra/devstack-gate/tree/README.rst>`_
describes the process of using devstack gate to run your own devstack
based tests.

For management of the devstack and other instances, a tool called
:ref:`nodepool` creates and deletes Jenkins slaves as needed in order to
maintain the pool.

Sysadmin
========

Jenkins is largely hidden, and has no sensitive data exposed
publicly, so we use self-signed certs for Jenkins masters.

After bringing up a jenkins node (16G memory instance if you use the
stock jenkins.default) with puppet, log in and configure Jenkins by
hand:

#. Configure the site so it knows it's correct url.
   (Jenkins URL in global config). This is needed to complete an SSO
   sign-in.

#. Configure the OpenID plugin for your SSO site (e.g. Launchpad)

#. Do not set CSRF protection - that causes problems with various components
   such as nodepool and swift log uploader.

#. Login.

#. Setup matrix security: add the 'authenticated' pseudo user and
   grant Admin access to your own user.

#. Setup one account per `http://docs.openstack.org/infra/jenkins-job-builder/installation.html#configuration-file`
   and grab the API token for it.

#. Configure the number of executors you want on the Jenkins Master
   (e.g. 1)

#. Configure a maven environment (if you have Maven projects to test).

#. Enable the gearman plugin globally.  Your gearman server is
   zuul.$project. If Test Connection fails, do a puppet run (puppet
   agent --test) on the zuul machine, as gearman wouldn't have started
   with no workers configured.

#. Configure the timestamper plugin. E.g. to
   '<b>'yyyy-MM-dd HH:mm:ss'</b> '

#. Enable the zmq plugin globally if it is visible. No settings were
   visible when writing this doc.

#. You will configure global scp and ftp credentials for static and
   docs sites respectively later, but as we haven't setup those sites
   yet, that's not possible :).

Puppet takes care of the rest.

Quirks
------

Note that jenkins talks to its slaves via ssh, the
modules/openstack_project/manifests/init.pp file contains the ssh
public key that puppet installs on the slaves.

Slaves
------

Statically provisioned slaves have labels assigned by hand. E.g.
centos6, and are added to a chosen Jenkins master by hand. Adding a
slave is then:

#. Launch a slave

#. Add it to Jenkins
   Add your jenkins master key for the credentials (make it global,
   one-time operation).
   Set the jenkins home to /home/jenkins

#. Set appropriate labels on it

#. Profit!

Safe Master Restarts
====================

Jenkins masters periodically leak threads reducing their job
throughput and eventually leading to crashes. We work around this
by performing weekly rolling restarts of the Jenkins masters with
an ansible playbook.

If you need to perform a safe restart against a single master you
can do this by running the same playbook and limiting it to a
specific jenkins master

To do this::

  root@puppetmaster# ansible-playbook -f1 --limit $server_fqdn \
      /opt/system-config/production/playbooks/restart_jenkins_masters.yaml \
      --extra-vars "user=hudson-openstack \
      password=$(/opt/system-config/production/tools/hieraedit.py \
      --yaml /etc/puppet/hieradata/production/fqdn/nodepool.openstack.org.yaml jenkins_api_key)"

Consider running this in screen as the worst case run time is as
long as our longest running job.

How to manually run jenkins job builder
=======================================

Jenkins job builder may need to be run manually under certain situations. If the expected
jobs are not being created in jenkins masters, running jjb manually on the masters where
it failed is suggested. To do this::

  user@jenkins01# sudo -H jenkins-jobs --conf /etc/jenkins_jobs/jenkins_jobs.ini \
      update --delete-old /etc/jenkins_jobs/config

Consider running this in screen as the worst case run time can be of several hours.

In the case of incorrect jobs configuration caused by some jjb malfunction, all jobs
will need to be regenerated. As jjb uses a local cache, to force the regeneration
of all jobs, the cache needs to be ignored. To do this::

  user@jenkins01# sudo -H jenkins-jobs --ignore-cache --conf \
      /etc/jenkins_jobs/jenkins_jobs.ini update --delete-old /etc/jenkins_jobs/config

In order to speed up the massive job reconfiguration, it may be desired to set jenkins
on shutdown mode, visiting this link::

`https://jenkins[xx].openstack.org/quietDown`

And make Jenkins alive again after job reconfiguration finishes.
