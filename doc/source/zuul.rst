:title: Zuul

.. _zuul:

Zuul
####

Zuul is a pipeline-oriented project gating system.  It facilitates
running tests and automated tasks in response to Gerrit events.

At a Glance
===========

:Hosts:
  * https://zuul.openstack.org
  * ze*.openstack.org
  * zm*.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-zuul/tree/
  * :cgit_file:`modules/openstack_project/manifests/zuul_prod.pp`
  * :cgit_file:`modules/openstack_project/manifests/zuul_dev.pp`
:Configuration:
  * :config:`zuul/`
  * :config:`zuul.d/`
:Projects:
  * https://git.zuul-ci.org/cgit/zuul
:Bugs:
  * https://storyboard.openstack.org/#!/project/openstack-infra/zuul
:Resources:
  * `Zuul Reference Manual <https://zuul-ci.org/docs/zuul>`_
:Chat:
  * #zuul on freenode

Overview
========

The OpenStack project uses a number of pipelines in Zuul, as defined
in :config:`zuul.d/pipelines.yaml`.

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
`<https://zuul.openstack.org/>`_.

Zuul's configuration is distributed across projects listed in
:config:`zuul/main.yaml`.  Anyone may propose a change to the
configuration by editing configuration in those projects and submitting
the change to Gerrit for review.

For the full syntax of Zuul's configuration file format, see the `Zuul
reference manual`_.

Sysadmin
========

Zuul and gear are lightweight - it should be possible to run both on a
1G instance for small deployments. OpenStack's deployment requires at
least a 8G instance at the time of writing, though additional cache
memory helps performance.

Zuul is mostly stateless, so the server does not need backing up (though
it does rely on a Trove instance for its build history). However zuul
talks through git and ssh so you will need to manually check ssh host
keys as the zuul user. e.g.::

  sudo su - zuul
  ssh -p 29418 review.openstack.org

To debug Zuul's gearman server, SSL is required.  Use the following
command::

  openssl s_client -connect localhost:4730 -cert /etc/zuul/ssl/client.pem  -key /etc/zuul/ssl/client.key

Restarts
--------

Zuul restarts are disruptive, so non-emergency restarts should always be
scheduled for quieter times of the day, week and cycle. To be as
courteous to developers as possible, just prior to a restart the `Zuul
Status Page <https://zuul.openstack.org/>`_ should be checked to
see the status of the gate. If there is a series of changes nearly
merged, wait until that has been completed.

Since Zuul is stateless, some work needs to be done to save and then
re-enqueue patches when restarts are done. To accomplish this, start by
running `zuul-changes.py
<https://git.zuul-ci.org/cgit/zuul/tree/tools/zuul-changes.py>`_
to save the check and gate queues::

  python /opt/zuul/tools/zuul-changes.py http://zuul.openstack.org \
    check >check.sh
  python /opt/zuul/tools/zuul-changes.py http://zuul.openstack.org \
    gate >gate.sh

These check.sh and gate.sh scripts will be used after the restart to
re-enqueue the changes.

Now use `service zuul-scheduler stop` to stop zuul and then run ps to
make sure the process has actually stopped, it may take several seconds
for it to finally go away.

When you are satisfied that zuul is up, first run the gate.sh script and
then check.sh to re-enqueue the changes from before the restart::

  ./gate.sh
  ./check.sh

You may watch the `Zuul Status Page
<https://zuul.openstack.org/>`_ to confirm that changes are
returning to the queues. This frontend is provided by the zuul-web
service on the same server, which may also need to be restarted.

Executors
---------

Servers with names matching the pattern ze*.openstack.org are Zuul
Executors.  These are horizontally scalable components of Zuul which
run Ansible within a Bubblewrap context and connect to job nodes.
They can be started and stopped at will, and new ones added as
necessary to accommodate load.

Mergers
-------

Servers with names matching the pattern zm*.openstack.org are Zuul
Mergers.  These are horizontally scalable components of Zuul which
perform git operations for the benefit of jobs. They can be started
and stopped at will, and new ones added as necessary to accommodate
load.

Secrets
-------

In some cases it may be warranted to compare the decrypted plaintext of
a secret from job configuration against a reference value while
troubleshooting, since random padding means encrypting the same
plaintext a second time will result in wholly different ciphertext. In
order to avoid unintentional disclosure this should only be done when
absolutely necessary, but it's possible to decrypt a secret locally on
the scheduler server with a command like the following (just extract the
secret ciphertext from the job configuration first to remove surrounding
YAML, there is no need to dedent nor recombine split lines)::

  cat ciphertext.txt | base64 -d | sudo openssl rsautl -decrypt -oaep -inkey \
  /var/lib/zuul/keys/secrets/project/gerrit/openstack-infra/project-config/0.pem
