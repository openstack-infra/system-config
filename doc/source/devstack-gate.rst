:title: Devstack Gate

.. _devstack-gate:

Devstack Gate
#############

Devstack-gate is a collection of scripts used by the OpenStack CI team
to test every change to core OpenStack projects by deploying OpenStack
via devstack on a cloud server.

At a Glance
===========

:Hosts:
  * http://jenkins.openstack.org/
  * http://devstack-launch.slave.openstack.org/
:Puppet:
  * :file:`modules/openstack_project/manifests/template.pp`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/devstack-gate
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
:Resources:
  * `Devstack-gate README <https://git.openstack.org/cgit/openstack-infra/devstack-gate/tree/README.rst>`_

Overview
========

All changes to core OpenStack projects are "gated" on a set of tests
so that it will not be merged into the main repository unless it
passes all of the configured tests. Most projects require unit tests
with pep8 and several versions of Python. Those tests are all run only
on the project in question. The devstack gate test, however, is an
integration test and ensures that a proposed change still enables
several of the projects to work together. Any proposed change to the
configured set of projects must pass the devstack gate test.

Obviously we test nova, glance, keystone, horizon, neutron and their
clients because they all work closely together to form an OpenStack
system. Changes to devstack itself are also required to pass this test
so that we can be assured that devstack is always able to produce a
system capable of testing the next change to nova. The devstack gate
scripts themselves are included for the same reason.

How It Works
============

The devstack test starts with an essentially bare virtual machine
made available by :ref:`nodepool` and prepares the testing
environment. This is driven by the the devstack-gate repository which
holds several scripts that are run by Jenkins.

When a proposed change is approved by the core reviewers, Jenkins
triggers the devstack gate test itself. This job runs on one of the
previously configured nodes and invokes the devstack-vm-gate-wrap.sh
script which checks out code from all of the involved repositories,
and merges the proposed change.  That script then calls
devstack-vm-gate.sh which installs a devstack configuration file, and
invokes devstack. Once devstack is finished, it runs exercise.sh which
performs some basic integration testing. After
everything is done, the script copies all of the log files back to the
Jenkins workspace and archives them along with the console output of
the run. The Jenkins job that does this is the somewhat awkwardly
named gate-integration-tests-devstack-vm.

How to Debug a Devstack Gate Failure
====================================

When Jenkins runs gate tests for a change, it leaves comments on the
change in Gerrit with links to the test run. If a change fails the
devstack gate test, you can follow it to the test run in Jenkins to
find out what went wrong. The first thing you should do is look at the
console output (click on the link labeled "[raw]" to the right of
"Console Output" on the left side of the screen). You'll want to look
at the raw output because Jenkins will truncate the large amount of
output that devstack produces. Skip to the end to find out why the
test failed (keep in mind that the last few commands it runs deal with
copying log files and deleting the test VM -- errors that show up
there won't affect the test results). You'll see a summary of the
devstack exercise.sh tests near the bottom. Scroll up to look for
errors related to failed tests.

You might need some information about the specific run of the test. At
the top of the console output, you can see all the git commands used
to set up the repositories, and they will output the (short) sha1 and
commit subjects of the head of each repository.

It's possible that a failure could be a false negative related to a
specific provider, especially if there is a pattern of failures from
tests that run on nodes from that provider. In order to find out which
provider supplied the node the test ran on, look at the name of the
jenkins slave near the top of tho console output, the name of the
provider is included.

Below that, you'll find the output from devstack as it installs all of
the debian and pip packages required for the test, and then configures
and runs the services. Most of what it needs should already be cached
on the test host, but if the change to be tested includes a dependency
change, or there has been such a change since the snapshot image was
created, the updated dependency will be downloaded from the Internet,
which could cause a false negative if that fails.

Assuming that there are no visible failures in the console log, you
may need to examine the log output from the OpenStack services. Back
on the Jenkins page for the build, you should see a list of "Build
Artifacts" in the center of the screen. All of the OpenStack services
are configured to syslog, so you may find helpful log messages by
clicking on "syslog.txt". Some error messages are so basic they don't
make it to syslog, such as if a service fails to start. Devstack
starts all of the services in screen, and you can see the output
captured by screen in files named "screen-\*.txt". You may find a
traceback there that isn't in syslog.

After examining the output from the test, if you believe the result
was a false negative, you can retrigger the test by re-approving the
change in Gerrit. If a test failure is a result of a race condition in
the OpenStack code, please take the opportunity to try to identify it,
and file a bug report or fix the problem. If it seems to be related to
a specific devstack gate node provider, we'd love it if you could help
identify what the variable might be (whether in the devstack-gate
scripts, devstack itself, OpenStack, or even the provider's service).

Developer Setup
===============

If you'd like to work on the devstack-gate scripts and test process,
see the README in the devstack-gate repo for specific instructions.
