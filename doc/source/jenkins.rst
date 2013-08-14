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
  * :file:`modules/jenkins`
  * :file:`modules/openstack_project/manifests/jenkins.pp`
  * :file:`modules/openstack_project/manifests/jenkins_dev.pp`
:Configuration:
  * :file:`modules/openstack_project/files/jenkins_job_builder/config/`
:Projects:
  * http://jenkins-ci.org/
  * :ref:`zuul`
  * :ref:`jjb`
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * https://wiki.jenkins-ci.org/display/JENKINS/Issue+Tracking
:Resources:
  * :ref:`zuul`
  * :ref:`jjb`

Overview
========

A large number and variety of jobs are defined in Jenkins.  The
configuration of all of those jobs is stored in git in the
openstack-infra/config repository.  They are defined in YAML files
that are read by :ref:`jjb` which configures the actual jobs in
Jenkins.

Anyone may submit a change to the openstack-infra/config repository
that defines a new job or alters an existing job by editing the
appropriate YAML files.  See :ref:`jjb` for more information.

Because of the large number of builds that Jenkins executes, the
OpenStack project favors the following approach in configuring Jenkins
jobs:

  * Minimal use of plugins: the more post-processing work that Jenkins
    needs to perform on a job, the more likely we are to run into
    compatibility problems among plugins, and contention for shared
    resources on the Jenkins master.  A number of popuplar plugins
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
devstack gate source can be found on `Github
<https://github.com/openstack-infra/devstack-gate>`_ and the `Readme
<https://github.com/openstack-infra/devstack-gate/blob/master/README.md>`_
describes the process of using devstack gate to run your own devstack
based tests.

The :ref:`devstack-gate` project is used to maintain a pool of Jenkins
slaves that are used to run these tests.  Devstack-gate jobs create
and delete Jenkins slaves as needed in order to maintain the pool.

Creating a Jenkins Slave
========================

Use the install_jenkins_slave.sh script to create a test server when you
want to test your Jenkins build jobs. Create a server and define a fully
qualified domain name for it by editing the /etc/hosts file::

127.0.0.1       my.fqdomainname.com

and then running::

sudo hostname my.fqdomainname.com

Lastly, run the install_jenkins_slave.sh script found in the root of the
config directory::

sudo ./install_jenkins_slave.sh

Once it has completed, you have a working puppet server and access to 
the script files locally. Verify the installation by listing the 
contents of the /usr/local/jenkins/slave_scripts/ directory::

root@precise-jenkins:~/src/config# ls /usr/local/jenkins/slave_scripts/
baremetal-archive-logs.sh  lvm-kexec-reset.sh                     run-cover.sh      subunit2html.py
baremetal-deploy.sh        markdown-docbook.sh                    run-docs.sh       tardiff.py
baremetal-os-install.sh    maven-properties.sh                    run-pep8.sh       update-pip-cache.sh
bump-milestone.sh          package-gerrit.sh                      run-pyflakes.sh   upstream_translation_update_manuals.sh
create-ppa-package.sh      ping.py                                run-pylint.sh     upstream_translation_update.sh
docbook-properties.sh      project-requirements-change.py         run-selenium.sh   wait_for_nova.sh
gerrit-git-prep.sh         propose_translation_update_manuals.sh  run-tarball.sh    wait_for_puppet.sh
jenkinsci-upload.sh        propose_translation_update.sh          run-tox.sh
jenkins-oom-grep.sh        pypi-extract-metadata.py               run-xmllint.sh
jenkins-sudo-grep.sh       pypi-upload.sh                         select-mirror.sh
