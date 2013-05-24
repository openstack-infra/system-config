:title: Logstash

.. _logstash:

Logstash
########

Logstash is a high-performance indexing and search engine for logs.

At a Glance
===========

:Hosts:
  * http://logstash.openstack.org
  * logstash-worker-\*.openstack.org
  * elasticsearch.openstack.org
:Puppet:
  * :file:`modules/logstash`
  * :file:`modules/openstack_project/manifests/logstash.pp`
  * :file:`modules/openstack_project/manifests/logstash_worker.pp`
  * :file:`modules/openstack_project/manifests/elasticsearch.pp`
:Configuration:
  * :file:`modules/openstack_project/files/logstash`
:Projects:
  * http://logstash.net/
  * http://kibana.org/
:Bugs:
  * http://bugs.launchpad.net/openstack-ci
  * https://logstash.jira.com/secure/Dashboard.jspa
  * https://github.com/rashidkpc/Kibana/issues

Overview
========

Logs from Jenkins test runs are sent to logstash where they are
indexed and stored.  Logstash facilitates reviewing logs from mulitple
sources in a single test run, searching for errors or particular
events within a test run, as well as searching for log event trends
across test runs.

TODO(clarkb): more details about system architecture

TODO(clarkb): useful queries

