:title: Zuul

.. _zuul:

Zuul
####

Zuul is a pipeline-oriented project gating system.  It facilitates
running tests and automated tasks in response to Gerrit events.

At a Glance
===========

:Hosts:
  * http://status.openstack.org/zuul
  * http://zuul.openstack.org
  * http://zuul-dev.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-zuul/tree/
  * :file:`modules/openstack_project/manifests/zuul_prod.pp`
  * :file:`modules/openstack_project/manifests/zuul_dev.pp`
:Configuration:
  * :config:`zuul/layout.yaml`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/zuul
:Bugs:
  * https://storyboard.openstack.org/#!/project/679
:Resources:
  * `Zuul Reference Manual <http://docs.openstack.org/infra/zuul>`_

Overview
========

The OpenStack project uses a number of pipelines in Zuul:

**check**
  Newly uploaded patchsets enter this pipeline to receive an initial
  +/-1 Verified vote from Jenkins.

**gate**
  Changes that have been approved by core developers are enqueued in
  order in this pipeline, and if they pass tests in Jenkins, will be
  merged.

**post**
  This pipeline runs jobs that operate after each change is merged.

**pre-release**
  This pipeline runs jobs on projects in response to pre-release tags.

**release**
  When a commit is tagged as a release, this pipeline runs jobs that
  publish archives and documentation.

**silent**
  This pipeline is used for silently testing new jobs.

**experimental**
  This pipeline is used for on-demand testing of new jobs.

**periodic**
  This pipeline has jobs triggered on a timer for e.g. testing for
  environmental changes daily.

Zuul watches events in Gerrit (using the Gerrit "stream-events"
command) and matches those events to the pipelines above.  If a match
is found, it adds the change to the pipeline and starts running
related jobs.

The **gate** pipeline uses speculative execution to improve
throughput.  Changes are tested in parallel under the assumption that
changes ahead in the queue will merge.  If they do not, Zuul will
abort and restart tests without the affected changes.  This means that
many changes may be tested in parallel while continuing to assure that
each commit is correctly tested.

Zuul's current status may be viewed at
`<http://status.openstack.org/zuul/>`_.

Zuul's configuration is stored in :config:`zuul/layout.yaml`.  Anyone
may propose a change to the configuration by editing that file and
submitting the change to Gerrit for review.

For the full syntax of Zuul's configuration file format, see the `Zuul
reference manual`_.

Sysadmin
========

Zuul and gear are lightweight - it should be possible to run both on a
1G instance for small deployments. OpenStack's deployment requires at
least a 2G instance at the time of writing.

Zuul is stateless, so the server does not need backing up. However
zuul talks through git and ssh so you will need to manually check ssh
host keys as the zuul user. e.g.::

  sudo su - zuul
  ssh -p 29418 review.openstack.org

Restarts
--------

Zuul restarts are disruptive, so non-emergency restarts should always be
scheduled for quieter times of the day, week and cycle. To be as
courteous to developers as possible, just prior to a restart the `Zuul
Status Page <http://status.openstack.org/zuul/>`_ should be checked to
see the status of the gate. If there is a series of changes nearly
merged, wait until that has been completed.

Since Zuul is stateless, some work needs to be done to save and then
re-enqueue patches when restarts are done. To accomplish this, start by
running `zuul-changes.py
<https://git.openstack.org/cgit/openstack-infra/zuul/tree/tools/zuul-changes.py>`_
to save the check and gate queues::

  python /opt/zuul/tools/zuul-changes.py http://zuul.openstack.org \
    check >check.sh
  python /opt/zuul/tools/zuul-changes.py http://zuul.openstack.org \
    gate >gate.sh

These check.sh and gate.sh scripts will be used after the restart to
re-enqueue the changes.

Now use `service zuul stop` to stop zuul and then run ps to make sure
the process has actually stopped, it may take several seconds for it to
finally go away.

With Zuul stopped, delete all the used nodes in nodepool. Wait for one
of each variety to come up before using `service zuul start` to start
zuul again.

Once Zuul is started, run netcat against localhost 4730 port to confirm
that all the node types (particularly the uncommon ones) are registered
with Gearman before re-enqueuing patches. For instance::

  echo "status" | nc localhost 4730 | grep :centos7

When you are satisfied that all the node types have returned, first run
the gate.sh script and then check.sh to re-enqueue the changes from
before the restart::

  ./gate.sh
  ./check.sh

You may watch the `Zuul Status Page
<http://status.openstack.org/zuul/>`_ to confirm that changes are
returning to the queues.
