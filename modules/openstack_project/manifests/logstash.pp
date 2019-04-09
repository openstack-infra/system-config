# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Logstash web frontend glue class.
#
class openstack_project::logstash (
  $discover_nodes = ['elasticsearch01.openstack.org:9200'],
  $statsd_host = 'graphite.opendev.org',
  $subunit2sql_db_host,
  $subunit2sql_db_pass,
) {
  class { 'logstash::web':
    frontend            => 'kibana',
    discover_nodes      => $discover_nodes,
    proxy_elasticsearch => true,
  }

  class { 'log_processor': }

  class { 'log_processor::geard':
    statsd_host => $statsd_host,
  }

  include 'subunit2sql'

  class { 'subunit2sql::server':
    db_host => $subunit2sql_db_host,
    db_pass => $subunit2sql_db_pass,
  }

  include 'simpleproxy'

  class { 'simpleproxy::server':
    db_host            => $subunit2sql_db_host,
  }
}
