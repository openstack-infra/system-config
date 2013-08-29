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
