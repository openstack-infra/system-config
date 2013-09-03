:title: Running your own CI infrastructure

.. _running-your-own:

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

* You need a cloud of some sort, all our tooling is built for OpenStack clouds :).

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

1. Clone the CI config repository and adjust it as necessary.

1. Manually boot a machine with ~2G of ram to be the puppetmaster.

1. Follow http://ci.openstack.org/puppet.html#id2 but use your repository
   rather than the OpenStack CI repository.

Changes required
================

site.pp
~~~~~~~

This file lists the specific servers you are running. Minimally you need a
ci-puppetmaster, gerrit (review), jenkins, jenkins01, puppet-dashboard,
nodepool, zuul, and then one or more slaves with appropriate distro choices.

A minimal site.pp can be useful to start with to get up and running. E.g.
delete all but the puppetmaster and default definitions.

modules/openstack_project
~~~~~~~~~~~~~~~~~~~~~~~~~

This tree defines the shape of servers (some of which are unique, some of which
are scaled horizonally, thus the separation). To run your own infrastructure we
recommend you copy the entire tree, delete any servers you won't run, and
replace hostnames and class names with yours throughout.

Some templates can be used as-is by leaving their references to point within the
openstack_project tree.

Bootstrapping
~~~~~~~~~~~~~
The minimum set of things to port across is:

* modules/openstack_project/manifests/params.pp

* modules/openstack_project/manifests/puppet_cron.pp

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

* The ci-puppetmaster definition in site.pp

* The puppet-dashboard definition in site.pp

Then follow the puppet.rsh instructions for bringing up a puppetmaster,
replacing openstack_project with your project name. You'll need to populate
hiera at the end with the minimum set of keys:

* sysadmins

* dashboard_password and dashboard_mysql_password

Copy in your cloud credentials to /root/ci-launch - e.g. to
``$projectname-rs.sh`` for a rackspace cloud.

Stage 2
~~~~~~~

Migrate:

* modules/openstack_project/manifests/dashboard.pp

Then start up your puppet dashboard (see :file:`launch/README` for full
details)::

    sudo su -
    cd /opt/config/production/launch
    . /root/ci-launch/
    export FQDN=servername.project.example.com
    puppet cert generate $FQDN
    ./launch-node.py $FQDN --server ci-puppetmaster.project.example.com

* This will chug for a while.

* Run the DNS update commands [nb: install your DNS API by hand at the moment]

* ssh into the new node and update its ``/etc/default/puppet`` to autostart
  per the launch README.

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

  * You need to modify te puppet path for gerrit acls - they should come from
    your project.

  * Ditto projects.yaml, which is passed in from your review.pp - something like
    $PROJECT/templates/review.projects.yaml.erb

  * set_agreements is a database migration tool for gerrit CLAs; not needed
    unless you have CLAs.

* modules/openstack_project/manifests/review.pp.

  * Contact store should be set to false as at this stage we don't have a
    secure store setup.

  * Start with just local replication, plus github if you have a github organisation already.

  * Ditto starting without gerritbot.

Create any acl config files for your project.

Update site.pp to reference the new gerrit manifest. See review.pp for
documentation on the hiera keys.

You will need to get an ssl certificate - if you're testing you may want a self
signed one. ``http://lmgtfy.com/q=self+signed+certificate``. To put them in
hiera you need to use ``: |``::

  foo: |
    literal
    contents
    here

Launch a node - be sure to pass --ram 10240 to get a flavor with at least 10G+
or RAM, as gerrit is configured for 8G of heap.

Follow the :file:`doc/source/gerrit.rst` for instructions on getting gerrit
configured once installed.
