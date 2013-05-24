:title: Jenkins

Jenkins
#######

Overview
========

Jenkins is a Continuous Integration system that runs tests and
automates some parts of project operations.  It is controlled for the
most part by :ref:`zuul` which determines what jobs are run when.

The OpenStack Jenkins can be found at `<http://jenkins.openstack.org>`_.

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
