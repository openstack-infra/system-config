:title: Running your own CI infrastructure

.. _running-your-own:

.. warning:: Parts of this file are out of date

Running your own CI infrastructure
##################################

The OpenStack CI infrastructure is designed to be shared amongst other projects
wanting a scalable cloud based CI system. We're delighted when someone wants to
reuse what we're building.

To avoid having lots of meta references in the rest of the system
documentation, we document most things targeted specifically for use in the
OpenStack CI system itself. This chapter acts as a patch to the rest of our
documentation explaining how to reuse the OpenStack CI infrastructure for
another project.

Requirements
============

* You need a cloud of some sort, all our tooling is built for
  OpenStack clouds :).

* A service account for your CI systems within that cloud/clouds.

* Optionally a service account for your Jenkins nodes (separation of concerns -
  this account has its credentials loaded into the cloud itself). You can run
  with one account, but then you risk a larger cascade compromise if there is
  a bug in nodepool.

* A domain for your servers to live in; puppet is hostname based, having
  everything in sync is just easier.

* A git repository that you can store your code in :).

Initial setup
=============

#. Manually boot a machine or VM with 2G+ of ram to be the puppetmaster.
   Average memory consumption is between 1GB-1.5GB with random peaks around
   2GB for puppetdb and ruby processes.

#. Clone the CI config repository and adjust it as necessary. Avoiding forks
   and overriding the default config from Infra is a good practice to
   customize your CI system. The CI config is split in 2 projects:
   a) `system-config <http://git.openstack.org/cgit/openstack-infra/system-config/>`_
   Contains information on how systems are operated.
   b) `project-config <http://git.openstack.org/cgit/openstack-infra/project-config/>`_
   Contains configuration data used by OpenStack projects and services.
   For more details on the config repo split, read the following spec:
   `http://specs.openstack.org/openstack-infra/infra-specs/specs/config-repo-split.html`

#. Follow http://ci.openstack.org/puppet.html#id2 and use your repository
   in addition to the OpenStack CI repository. This is appropriate to stay in
   sync with OpenStack Infra team rolling out new functionality and at the same
   time applying the necessary customizations through the config overrides.
   This step consists in configuring puppetmaster to load CI config into
   modulepath for both Infra projects and your custom CI repository.
   The necessary changes are explained in the sections below.

Changes required
================

site.pp
~~~~~~~

This file lists the specific servers you are running. Minimally you need a
puppetmaster, gerrit (review), jenkins (secure jobs such as making
releases), jenkins01 (untrusted jobs from any code author), puppetboard,
nodepool, zuul, and then one or more slaves with appropriate distro choices.

A minimal site.pp can be useful to start with to get up and running. E.g.
delete all but the puppetmaster and default definitions.

modules/openstack_project
~~~~~~~~~~~~~~~~~~~~~~~~~

This tree defines the shape of servers (some of which are unique, some of which
are scaled horizonally, thus the separation). To run your own infrastructure we
recommend you copy the entire tree, delete any servers you won't run, and
replace hostnames and class names with yours throughout.

Some templates can be used as-is by leaving their references to point
within the openstack_project tree.

Bootstrapping
~~~~~~~~~~~~~
The minimum set of things to port across is:

* modules/openstack_project/manifests/params.pp

* modules/openstack_project/manifests/server.pp

* modules/openstack_project/manifests/template.pp

* modules/openstack_project/manifests/automatic_upgrades.pp

* modules/openstack_project/manifests/base.pp
  May need additional changes beyond the search/replace?
  - User list.

* modules/openstack_project/manifests/users.pp

* modules/openstack_project/manifests/puppetmaster.pp

* modules/openstack_project/templates/puppet.conf.erb

* The default node definition in site.pp

* The puppetmaster definition in site.pp

* The puppetdb definition in site.pp

Then follow the :ref:`puppet-master` instructions for bringing up a
puppetmaster, replacing openstack_project with your project name.
You'll need to populate hiera at the end with the minimum set of keys:

* sysadmins

Copy in your cloud credentials to /root/ci-launch - e.g. to
``$projectname-rs.sh`` for a rackspace cloud.

Stage 2
~~~~~~~

Migrate:

* modules/openstack_project/manifests/puppetdb.pp

Then start up your puppet db with puppet board (see :file:`launch/README`
for full details)::

    sudo su -
    cd /opt/system-config/production/launch
    . /root/ci-launch/
    export FQDN=servername.project.example.com
    puppet cert generate $FQDN
    ./launch-node.py $FQDN --server puppetmaster.project.example.com

* This will chug for a while.

* Run the DNS update commands [nb: install your DNS API by hand at the moment]

Stage 3 - gerrit
~~~~~~~~~~~~~~~~

Gerrit is combined master repository management and code review system. See
:file:`doc/source/gerrit.rst` for the common operational tasks for it.

To set it up, you'll need a small png 167px x 56x with a project logo for
branding and a 485px × 161px png as the top of page background. You can of
course alter the appearance and css to your hearts content.

In addition you need to set a dozen or so hiera variables (see site.pp), these
will require manually creating keys and passwords.

Migrate the manifests:

* modules/openstack_project/manifests/gerrit.pp. Note that this is a thin shim
  over a generic gerrit module: you'll be forking most of this and maintaining
  it indefinitely. If you don't want a CLA, be sure to elide those portions.
  Replace the file paths for branding files you've replaced. Many of the
  scripts can be used from openstack_projects though (which ones is yet to be
  determined).

  * All the '=> absent' cronjobs can be elided: they are cleanup for older
    versions of this manifest.

  * the LP links that reference openstack specifically should instead point to
    your project (or project group) on Launchpad [or wherever you want them].

  * openstackwatch creates an rss feed of the unified changes from many
    projects - it is entirely optional.

  * The cla files should be skipped or forked; they are specific to OpenStack.

  * The title and page-bkg are OpenStack specific and should be replaced.

  * The GerritSite.css is OpenStack specific - it references the
    openstack-page-bkg image.

  * The gerritsyncusers cron reference can be dropped.

  * The sync_launchpad_users cron reference can be dropped.

  * You need to modify the puppet path for gerrit acls - they should come from
    your project - make the directory but you can leave it empty (except for a
    . file to let git add it).  The `Project Creator's Guide <http://docs.openstack.org/infra/manual/creators.html>`_
    covers how it gets populated when your infrastructure is working.

  * Ditto projects.yaml and projects.ini, which is passed in from your
    review.pp - something like $PROJECT/files/review.projects.yaml
    and $PROJECT/templates/review.projects.ini.erb

  * set_agreements is a database migration tool for gerrit CLAs; not needed
    unless you have CLAs.

* modules/openstack_project/manifests/review.pp.

  * Contact store should be set to false as at this stage we don't have a
    secure store setup.

  * Start with just local replication, plus github if you have a
    github organisation already.

  * Ditto starting without gerritbot.

  * Be sure to update projects_file - that is openstack specific.
    The defaults at the top all need to be updated. You probably want to start
    with no initial projects until gerrit is happy for you, and update the
    defaults to match your project. The gerrit user and commit defaults should
    be changed, as should the homepage, but the rest should be fine.

Create any acl config files for your project.

Update site.pp to reference the new gerrit manifest. See review.pp for
documentation on the hiera keys.

SSH keys can be made via ssh-keygen, you will need passwordless keys to be able
to restart without manual intervention. See the ssh-keygen man page for more
information. but in short::

  ssh-keygen -t rsa -P '' -f ssh_host_rsa_key
  ssh-keygen -t dsa -P '' -f ssh_host_dsa_key
  ssh-keygen -t rsa -P '' -f project_ssh_rsa_key

You will need to get an ssl certificate - if you're testing you may want a self
signed one (but be sure to set ssl_chain_file to '' in review.pp in that case).
``http://lmgtfy.com/q=self+signed+certificate``. To put them in hiera you need
to use ``: |``::

  foo: |
    literal
    contents
    here

Launch a node - be sure to pass --flavor "10G" to get a flavor with at
least 10G+ of RAM, as gerrit is configured for 8G of heap.

Follow the :file:`doc/source/gerrit.rst` for instructions on getting gerrit
configured once installed.

Finally, you should be able to follow the `Project Creator’s Guide <http://docs.openstack.org/infra/manual/creators.html>`_ to setup a project at
this point. (Zuul and Jenkins jobs obviously won't work yet).

Stage 4 - Zuul
~~~~~~~~~~~~~~

Zuul is the scheduler in the OpenStack CI system queuing and dispatching work
across multiple CI engines (via gearman). With a working code review system we
can now set up a scheduler.  Once setup, new patches uploaded
to gerrit should be picked up and have a zuul verification fail (with 'LOST'
which indicates the Jenkins environment is gone).

#. Create a zuul user (the upstream site.pp uses jenkins for
   historical reasons):

   ::

     ssh-keygen -t rsa -P '' -f zuul_ssh_key

     cat zuul_ssh_key.pub | ssh -p 29418 $USER@$HOST gerrit create-account \
       --group "'Continuous Integration Tools'" \
       --full-name "'Zuul'" \
       --email zuul@lists.openstack.org \
       --ssh-key - zuul

#. Add the private key you made to hiera as ``zuul_ssh_private_key_contents``.

#. Migrate modules/openstack_project/zuul/layout.yaml. This file has both
   broad structure such as pipelines which you'll want to preserve
   as-is, and project specific entries that you'll want to delete. And probably
   update the error links to point to your own wiki.

   Be sure to keep the ^.*$ job parameter.

#. Migrate modules/openstack_project/manifests/zuul_prod.pp into your project
   tree.

#. Migrate modules/openstack_project/zuul/scoreboard.html into your tree. This
   file is used for diagnosing intermittent failures : if you don't have flakey
   tests you can just trim this from the zuul definition.

#. Migrate the definition in site.pp to your project.
   Note the jenkins -> zuul user and variable change.
   You have no gearman workers yet, so make that list be empty.

#. Launch it, using a 1GB node.

Stage 5 - Jenkins Master(s)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

For Zuul to schedule work, it needs one or more Gearman connected Jenkins
masters. See :ref:`jenkins` for details.

The minimum setup is one master, but if you will be permitting any code
submitter to trigger test runs, we recommend having two: one untrusted and one
trusted for doing release automation (where the released code integrity is
important). When doing bring-up, bringing up jenkins01 first is probably
best as that is the first of the horizontally-scalable untrusted masters,
which get the most load (as they run jobs from anyone).

#. Make a jenkins master ssh key (shared across all jenkins masters):

   ::

     ssh-keygen -t rsa -P '' -f jenkins_ssh_key

#. Make a self signed certificate for the jenkins site.

#. Migrate modules/openstack_project/manifests/init.pp
   This gets the public jenkins key embedded in it.

#. Setup an equivalent to
   modules/openstack_project/files/jenkins_job_builder/config for your project.
   This is documented in the `Project Creator's Guide <http://docs.openstack.org/infra/manual/creators.html>`_. You should copy hooks.yaml and
   defaults.yaml across as-is, and if you want the stock set of python jobs
   that OpenStack uses, the python-jobs.yaml and pypi-jobs.yaml files too.
   Macros.yaml will need to be copied and customised.  See the
   jenkins-job-builder docs for information on customisation - failing to
   customise isn't harmful, but you may find your jobs try to post errors to
   the OpenStack logging site :).  Finally setup the list of projects to build
   in projects.yaml.  The ``config`` job  with the puppet-lint/syntax and
   pyflakes job can be particularly useful for ensuring you can push updates
   with confidence (which needs puppet-modules-jobs.yaml).

#. Migrate modules/openstack_project/files/jenkins/jenkins.default unless you
   are happy with a 12G java memory footprint (which only large busy sites will
   need).

#. Migrate modules/openstack_project/manifests/jenkins.pp
   Be sure to replace gerrig with your actual service account user.

#. Migrate jenkins01.openstack.org in site.pp. As we don't have zmq setup yet,
   leave that list blank. Be sure to add this jenkins into the zuul gear list.

#. Update hiera with the relevant parameters.
   You'll need to get the jenkins_jobs_password from Jenkins (see
   `http://ci.openstack.org/jenkins-job-builder/installation.html#configuration-file`)
   after Jenkins is up - start with it set to ''.  You can use your own user or
   make a dedicated user.

#. Launch the node with a size larger than the jenkins size you specified.

#. Setup Jenkins per :ref:`jenkins`.

At this stage doing a 'recheck' should still report LOST on a change.
But in the zuul debug.log in /var/log/zuul you should see a 'build xxx not
registered' being reported from gearman : this indicates you have never had an
executor register itself for that queue, and it's being ignored.

Stage 6 - Static slaves
~~~~~~~~~~~~~~~~~~~~~~~

The OpenStack CI infrastructure has two sets of Jenkins slaves : dynamically
managed via nodepool and statically managed by hand. A by-hand slave is easier
to bring up initially, so that's our next step.

The platform specific slaves are named $platform-serial.slave.$PROJECT in
site.pp. For instance, Python2.6 is not widely available now, so it runs on
centos6-xx.slave.$platform nodes. There can be multiple slaves, and each
gets their own puppet cert. The openstack/site.pp has a legacy setting for
``certname`` that you should remove.

#. Migrate modules/openstack_project/manifests/slave.pp
   We reuse tmpcleanup as-is.

#. Convert a slave definition in site.pp. Lets say
   ``/^centos6-?\d+\.slave\.openstack\.org$/``

#. Remove the certname override - upstream are dropping this gradually.

#. Launch a node, passing in --image and --flavor to get a node that you
   want :). e.g::

     launch-node.py centos6-1.slave.openstack.org --image $IMAGE --flavor "1G" \
       mydns

#. Go into the Jenkins config and press 'test connection' on the gearman config
   to register the new slave.

Now, if you push a change, zuul should pick it up and run it on
jenkins, and you can get onto the interesting thing of debugging why
it fails.

Later chapters will cover setting up the test storage servers so you can see
build history without logging into Jenkins.
