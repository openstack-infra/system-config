:title: Zuulv3

.. _zuulv3:

Zuul v3
#######

.. note:: Zuul v3 is the upcoming release of Zuul. While it is not in
          production yet, we are running it. Once it goes live, this
          document should be renamed to Zuul and the old document should
          go away - so don't develop any emotional attachments to permalinks
          to this document.

Zuul is a pipeline-oriented project gating system.  It facilitates
running tests and automated tasks in response to Code Review events.

At a Glance
===========

:Hosts:
  * http://zuulv3.openstack.org
  * zuulv3.openstack.org
  * ze*.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-zuul/tree/
  * https://git.openstack.org/cgit/openstack-infra/puppet-openstackci/tree/manifests/zuul.pp
:Configuration:
  * :config:`zuul/main.yaml`
  * :config:`zuul.yaml`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/zuul/tree/?h=feature/zuulv3
:Bugs:
  * https://storyboard.openstack.org/#!/project/679
:Resources:
  * `Zuul Reference Manual`_
:Chat:
  * #zuul on freenode

Overview
========

The OpenStack project uses a number of pipelines in Zuul:

**check**
  Newly uploaded patchsets enter this pipeline to receive an initial
  +/-1 Verified vote.

**gate**
  Changes that have been approved by core developers are enqueued in
  order in this pipeline, and if they pass tests, will be merged.

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
`<http://zuulv3.openstack.org/>`_.

Zuul's configuration is stored in :config:`zuul/main.yaml`.  Anyone
may propose a change to the configuration by editing that file and
submitting the change to Gerrit for review.

For the full syntax of Zuul's configuration file format, see the `Zuul
reference manual`_.

Sysadmin
========

Zuul has three main subsystems:

* Zuul Scheduler
* Zuul Executors
* Zuul Web

that in OpenStack's deployment depend on four 'external' systems:

* Nodepool
* Zookeeper
* gear
* MySQL

Scheduler
---------

The Zuul Scheduler and gear are all co-located on a single host,
zuulv3.openstack.org.

Zuul is stateless, so the server does not need backing up. However
zuul talks through git and ssh so you will need to manually check ssh
host keys as the zuul user.

.. note:: Is this still true or are we managing host keys in puppet now?

e.g.::

  sudo su - zuul
  ssh -p 29418 review.openstack.org

The Zuul Scheduler talks to Nodepool using Zookeeper and distributes work to
the executors using gear.

OpenStack's Zuul installation is also configured to write job results into
a MySQL database via the SQL Reporter plugin. The database for that is a
Rackspace Cloud DB and is configured in the ``mysql`` entry of the
``zuul_connection_secrets`` entry for the ``zuulv3.openstack.org`` FQDN.

Restarting the Scheduler
------------------------

Zuul Scheduler restarts are disruptive, so non-emergency restarts should
always be scheduled for quieter times of the day, week and cycle. To be as
courteous to developers as possible, just prior to a restart the `Zuul
Status Page`_ should be checked to see the status of the gate. If there is a
series of changes nearly merged, wait until that has been completed.

Since Zuul is stateless, some work needs to be done to save and then
re-enqueue patches when restarts are done. To accomplish this, start by
running `zuul-changes.py
<https://git.openstack.org/cgit/openstack-infra/zuul/tree/tools/zuul-changes.py>`_
to save the check and gate queues::

  python /opt/zuul/tools/zuul-changes.py http://zuulv3.openstack.org \
    check >check.sh
  python /opt/zuul/tools/zuul-changes.py http://zuulv3.openstack.org \
    gate >gate.sh

These check.sh and gate.sh scripts will be used after the restart to
re-enqueue the changes.

Now use `service zuul stop` to stop zuul and then run ps to make sure
the process has actually stopped, it may take several seconds for it to
finally go away.

Once you're ready, use `service zuul start` to start zuul again.

To re-enqueue saved jobs, first run the gate.sh script and then check.sh to
re-enqueue the changes from before the restart::

  ./gate.sh
  ./check.sh

You may watch the `Zuul Status Page`_ to confirm that changes are
returning to the queues.

Executors
---------

The Zuul Executors are a horizontally scalable set of servers named
ze*.openstack.org. They perform git merging operations for the scheduler
and execute Ansible playboks to actually run jobs.

Our jobs are configured to upload as much information as possible along with
their logs, but if there is an error which can not be diagnosed in that
manner, logs are available in the executor-debug log file on
the executor host.  You may use the Zuul build UUID to track
assignment of a given job from the Zuul scheduler to the Zuul executor
used by that job.

It is safe, although not free, to restart executors. If an executor goes away
the scheduler will reschedule the jobs it was originally running.

Web
---

Zuul Web is a horizontally scalable service. It is currently running colocated
with the scheduler on zuulv3.openstack.org. Zuul Web provides live console
streaming and will be the home of various web dashboards such as the status
page.

Zuul Web is stateless so is safe to restart, however restarting it will result
in a loss of connection for anyone watching a live-stream of a console log
when the restart happens.

.. _zuul_github_projects:

GitHub Projects
===============

OpenStack does not use GitHub for development purposes, but there are some
non-OpenStack projects in the broader ecosystem that we care about who do.
When we are interested in setting up jobs in Zuul to test the interaction
between OpenStack projects and those ecosystem projects, we can add the
OpenStack Zuul GitHub app to those projects, then configure them in Zuul.

In order to add the GitHub app to a project, an admin on that project should
nagivate to the `OpenStack Zuul`_ app in the GitHub UI. From there they can
click "Install", then choose the project or organization they want to install
the App on.

The repository then needs to be added to the `zuul/main.yaml` file before Zuul
can be configured to actually run jobs on it.

Information about the configuration of the OpenStack Zuul App itself can be
found on the :ref:`github` page at :ref:`openstack_zuul_app`.

.. _OpenStack Zuul: https://github.com/apps/openstack-zuul
.. _Zuul Reference Manual: https://docs.openstack.org/infra/zuul/feature/zuulv3
.. _Zuul Status Page: http://zuulv3.openstack.org
