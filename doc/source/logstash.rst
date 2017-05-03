:title: Logstash

.. _logstash:

Logstash
########

Logstash is a high-performance indexing and search engine for logs.

At a Glance
===========

:Hosts:
  * http://logstash.openstack.org
  * logstash-worker\*.openstack.org
  * elasticsearch\*.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-logstash/tree/
  * :cgit_file:`modules/openstack_project/manifests/logstash.pp`
  * :cgit_file:`modules/openstack_project/manifests/logstash_worker.pp`
  * :cgit_file:`modules/openstack_project/manifests/elasticsearch.pp`
:Configuration:
  * :cgit_file:`modules/openstack_project/files/logstash`
  * :cgit_file:`modules/openstack_project/templates/logstash`
  * `submit-logstash-jobs defaults`_
:Projects:
  * http://logstash.net/
  * http://kibana.org/
  * http://www.elasticsearch.org/
  * http://crm114.sourceforge.net/
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * https://logstash.jira.com/secure/Dashboard.jspa
  * https://github.com/rashidkpc/Kibana/issues
  * https://github.com/elasticsearch/elasticsearch/issues

Overview
========

Logs from Zuul test runs are sent to logstash where they are
indexed and stored.  Logstash facilitates reviewing logs from multiple
sources in a single test run, searching for errors or particular
events within a test run, as well as searching for log event trends
across test runs.

System Architecture
===================

There are four major layers in our Logstash setup.

1. Submit Logstash Jobs.
   The `logs post-playbook`_ in the Zuul ``base`` job submit logs defined
   in the `submit-logstash-jobs defaults`_ to a Logstash Indexer.
2. Logstash Indexer.
   Reads these log events from the log pusher, filters them to remove
   unwanted lines, collapses multiline events together, and parses
   useful information out of the events before shipping them to
   ElasticSearch for storage and indexing.
3. ElasticSearch.
   Provides log storage, indexing, and search.
4. Kibana.
   A Logstash oriented web client for ElasticSearch. You can perform
   queries on your Logstash logs in ElasticSearch through Kibana using
   the Lucene query language.

Each layer scales horizontally. As the number of logs grows we can add
more log pushers, more Logstash indexers, and more ElasticSearch nodes.
Currently we have multiple Logstash worker nodes that pair a log pusher
with a Logstash indexer. We did this as each Logstash process can only
dedicate a single thread to filtering log events which turns into a
bottleneck very quickly. This looks something like:

::

            zuul post-logs playbook
                     |
                     |
               gearman-client ---------------
                /    |    \                 |
               /     |     \                |
          gearman gearman gearman    subunit gearman
          worker1 worker2 worker3       worker01
              |      |      |               |
         logstash logstash logstash         |
         indexer1 indexer2 indexer3         |
              \      |      /          subunit2sql
               \     |     /                DB
               elasticsearch
                  cluster
                     |
                     |
                  kibana

Log Pusher
----------

This is an ansible module in the `submit-log-processor-jobs role`_. It
submits Gearman jobs to push log files into logstash.

Log pushing looks like this:

* Zuul runs post-playbook on job completion.
* Using info in the Gearman job log files are retrieved.
* Log files are processed then shipped to Logstash.

Using Gearman allows us to scale the number of log pushers
horizontally. It is as simple as adding another process that talks to
the Gearman server.

If you are interested in technical details the source of these scripts
can be found at

* https://git.openstack.org/cgit/openstack-infra/puppet-log_processor/tree/files/log-gearman-client.py
* https://git.openstack.org/cgit/openstack-infra/puppet-log_processor/tree/files/log-gearman-worker.py

Subunit Gearman Worker
----------------------

Using the same mechanism as the Log pushers there is an additional class of
gearman worker that takes the subunit output from test runs and stores them in
a subunit2SQL database. Right now this is only done with the subunit output
from gate and periodic queue tempest runs.

If you are interested in technical details the source of this script can be
found at:

* https://git.openstack.org/cgit/openstack-infra/puppet-subunit2sql/tree/files/subunit-gearman-worker.py


Logstash
--------

Logstash does the heavy lifting of squashing all of our log lines into
events with a common format. It reads the JSON log events from the log
pusher connected to it, deletes events we don't want, parses log lines
to set the timestamp, message, and other fields for the event, then
ships these processed events off to ElasticSearch where they are stored
and made queryable.

At a high level Logstash takes:

::

  {
    "fields" {
      "build_name": "gate-foo",
      "build_numer": "10",
      "event_message": "2013-05-31T17:31:39.113 DEBUG Something happened",
    },
  }

And turns that into:

::

  {
    "fields" {
      "build_name": "gate-foo",
      "build_numer": "10",
      "loglevel": "DEBUG"
    },
    "@message": "Something happened",
    "@timestamp": "2013-05-31T17:31:39.113Z",
  }

It flattens each log line into something that looks very much like
all of the other events regardless of the source log line format. This
makes querying your logs for lines from a specific build that failed
between two timestamps with specific message content very easy. You
don't need to write complicated greps instead you query against a
schema.

The config file that tells Logstash how to do this flattening can be
found at
https://git.openstack.org/cgit/openstack-infra/logstash-filters/tree/filters/openstack-filters.conf

This works via the tags that are associated with a given message.

The tags in
https://git.openstack.org/cgit/openstack-infra/logstash-filters/tree/filters/openstack-filters.conf
are used to tell logstash how to parse a given file's messages, based
on the file's message format.

When adding a new file to be indexed to
http://git.openstack.org/cgit/openstack-infra/project-config/tree/roles/submit-logstash-jobs/defaults/main.yaml
at least one tag from the openstack-filters.conf file should be associated
with the new file.  One can expect to see '{%logmessage%}' instead of
actual message data if indexing is not working properly.

In the event a new file's format is not covered, a patch for
https://git.openstack.org/cgit/openstack-infra/logstash-filters/tree/filters/openstack-filters.conf
should be submitted with an appropriate parsing pattern.

ElasticSearch
-------------

ElasticSearch is basically a REST API layer for Lucene. It provides
the storage and search engine for Logstash. It scales horizontally and
loves it when you give it more memory. Currently we run a multi-node
cluster on large VMs to give ElasticSearch both memory and disk space.
Per index (Logstash creates one index per day) we have N+1 replica
redundancy to distribute disk utilization and provide high availability.
Each replica is broken into multiple shards providing increased indexing
and search throughput as each shard is essentially a valid mini index.

To check on the cluster health, run this command on any es.* node::

  curl -XGET 'http://localhost:9200/_cluster/health?pretty=true'

Kibana
------

Kibana is a ruby app sitting behind Apache that provides a nice web UI
for querying Logstash events stored in ElasticSearch. Our install can
be reached at http://logstash.openstack.org. See
:ref:`query-logstash` for more info on using Kibana to perform
queries.

subunit2SQL
-----------
subunit2SQL is a python project for taking subunit v2 streams and storing them
in a SQL database. More information on the subunit protocol can be found here:
https://github.com/testing-cabal/subunit/blob/master/README

subunit2sql provides a database schema, several utilities for interacting with
the database, and a python library to build tooling on top of the database.
More information about using subunit2sql can be found at:
http://docs.openstack.org/developer/subunit2sql/

Our instance of the subunit2SQL database is running on a MySQL database and has
been configured to be remotely accessible to allow for public querying. The
public query access is provided with the following credentials::

   username: query
   password: query
   hostname: logstash.openstack.org
   database name: subunit2sql
   database port: 3306

simpleproxy
-----------
Simpleproxy is a simple tcp proxy which allows forwarding tcp connections from
one host to another. We use it to forward mysql traffic from a publicly
accessible host to the trove instance running the subunit2sql MySQL DB. This
allows for public access to the data on the database through the host
logstash.openstack.org.

.. _query-logstash:

Querying Logstash
=================

Hop on over to http://logstash.openstack.org and by default you get the
last 15 minutes of everything Logstash knows about in chunks of 100.
We run a lot of tests but it is possible no logs have come in over the
last 15 minutes, change the dropdown in the top left from ``Last 15m``
to ``Last 60m`` to get a better window on the logs. At this point you
should see a list of logs, if you click on a log event it will expand
and show you all of the fields associated with that event and their
values (note Chromium and Kibana seem to have trouble with this at times
and some fields end up without values, use Firefox if this happens).
You can search based on all of these fields and if you click the
magnifying glass next to a field in the expanded event view it will add
that field and value to your search. This is a good way of refining
searches without a lot of typing.

The above is good info for poking around in the Logstash logs, but
one of your changes has a failing test and you want to know why. We
can jumpstart the refining process with a simple query.

``@fields.build_change:"$FAILING_CHANGE" AND @fields.build_patchset:"$FAILING_PATCHSET" AND @fields.build_name:"$FAILING_BUILD_NAME" AND @fields.build_number:"$FAILING_BUILD_NUMBER"``

This will show you all logs available from the patchset and build pair
that failed. Chances are that this is still a significant number of
logs and you will want to do more filtering. You can add more filters
to the query using ``AND`` and ``OR`` and parentheses can be used to
group sections of the query. Potential additions to the above query
might be

* ``AND @fields.filename:"logs/syslog.txt"`` to get syslog events.
* ``AND @fields.filename:"logs/screen-n-api.txt"`` to get Nova API events.
* ``AND @fields.loglevel:"ERROR"`` to get ERROR level events.
* ``AND @message"error"`` to get events with error in their message.
  and so on.

General query tips:

* Don't search ``All time``. ElasticSearch is bad at trying to find all
  the things it ever knew about. Give it a window of time to look
  through. You can use the presets in the dropdown to select a window or
  use the ``foo`` to ``bar`` boxes above the frequency graph.
* Only the @message field can have fuzzy searches performed on it. Other
  fields require specific information.
* This system is growing fast and may not always keep up with the load.
  Be patient. If expected logs do not show up immediately after the
  Zuul job completes wait a few minutes.

crm114
=======

In an effort to assist with automated failure detection, the infra team
has started leveraging crm114 to classify and analyze the messages stored
by logstash.

The tool utilizes a statistical approach for classifying data, and is
frequently used as an email spam detector.  For logstash data, the idea
is to flag those log entries that are not in passing runs and only in
failing ones, which should be useful in pinpointing what caused the
failures.

In the OpenStack logstash system, crm114 attaches an error_pr attribute
to all indexed entries.  Values from -1000.00 to -10.00 should be considered
sufficient to get all potential errors as identified by the program.
Used in a kibana query, it would be structured like this:

::

  error_pr:["-1000.0" TO "-10.0"]


This is still an early effort and additional tuning and refinement should
be expected.  Should the crm114 settings need to be tuned or expanded,
a patch may be submitted for this file, which controls the process:
https://git.openstack.org/cgit/openstack-infra/puppet-log_processor/tree/files/classify-log.crm

.. _logs post-playbook: http://git.openstack.org/cgit/openstack-infra/project-config/tree/playbooks/base/post-logs.yaml
.. _submit-logstash-jobs defaults: http://git.openstack.org/cgit/openstack-infra/project-config/tree/roles/submit-logstash-jobs/defaults/main.yaml
.. _submit-log-processor-jobs role: http://git.openstack.org/cgit/openstack-infra/project-config/tree/roles/submit-log-processor-jobs
