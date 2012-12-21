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

Jenkins is essentially a job queing system, and everything that is done
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

Devstack Gate
=============

Currently OpenStack integration testing is performed by the devstack
gate test framework. This framework runs the devstack exercises and
Tempest smoketests against a devstack install on single use cloud
servers. The devstack gate source can be found on
`Github <https://github.com/openstack-infra/devstack-gate>`_ and the
`Readme <https://github.com/openstack-infra/devstack-gate/blob/master/README.md>`_
describes the process of using devstack gate to run your own devstack
based tests.
