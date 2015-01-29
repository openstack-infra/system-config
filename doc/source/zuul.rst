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
  * `Zuul Reference Manual <http://ci.openstack.org/zuul>`_

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
