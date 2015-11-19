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
# Logstash indexer worker glue class.
#
class openstack_project::logstash_worker (
  $discover_nodes = [ 'localhost:9200' ],
) {
  file { '/etc/default/logstash-indexer':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/openstack_project/logstash/logstash-indexer.default',
  }

  class { 'logstash::indexer':
    conf_template => 'openstack_project/logstash/indexer.conf.erb',
  }

  include log_processor
  log_processor::worker { 'A':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
  log_processor::worker { 'B':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
  log_processor::worker { 'C':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
  log_processor::worker { 'D':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
}
