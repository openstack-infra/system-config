:title: Grafana

.. _grafana:

Grafana
#######

Grafana is an open source, feature rich metrics dashboard and graph editor for
Graphite, InfluxDB & OpenTSDB. Openstack runs Graphite which stores all the
metrics related to Nodepool, Zuul and Jenkins (to name a few).

At a Glance
===========

:Hosts:
  * http://grafana.openstack.org
:Puppet:
  * https://github.com/bfraser/puppet-grafana
  * :file:`modules/openstack_project/manifests/grafana.pp`
:Projects:
  * http://grafana.org
:Bugs:
  * https://storyboard.openstack.org/#!/project/748

Overview
========

Apache is configured as a reverse proxy and there is a MySQL database
backend.


Sysadmin
========

After bringing up a Grafana node with puppet, log in and configure Grafana by
hand:

#. Log in as username: admin, password: admin.

#. Change the admin profile email 'XXX@openstack.org' and update the password
   to 'XXX'.

#. Under 'Data Sources', add a new entry with type as 'Grafana' and url as
   http://graphite.openstack.org.
