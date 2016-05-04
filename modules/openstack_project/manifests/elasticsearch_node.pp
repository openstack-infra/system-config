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
# Elasticsearch server glue class.
#
class openstack_project::elasticsearch_node (
  $discover_nodes = ['localhost'],
  $heap_size = '30g',
) {
  class { 'logstash::elasticsearch': }

  class { '::elasticsearch':
    es_template_config => {
      'index.store.compress.stored'          => true,
      'index.store.compress.tv'              => true,
      'indices.memory.index_buffer_size'     => '33%',
      'indices.breaker.fielddata.limit'      => '70%',
      'bootstrap.mlockall'                   => true,
      'gateway.recover_after_nodes'          => '5',
      'gateway.recover_after_time'           => '5m',
      'gateway.expected_nodes'               => '6',
      'discovery.zen.minimum_master_nodes'   => '4',
      'discovery.zen.ping.multicast.enabled' => false,
      'discovery.zen.ping.unicast.hosts'     => $discover_nodes,
      'http.cors.enabled'                    => true,
      'http.cors.allow-origin'               => "'*'", # lint:ignore:double_quoted_strings
    },
    heap_size          => $heap_size,
    version            => '1.7.5',
  }

  cron { 'delete_old_es_indices':
    ensure      => 'absent',
    user        => 'root',
    hour        => '2',
    minute      => '0',
    command     => 'curl -sS -XDELETE "http://localhost:9200/logstash-`date -d \'10 days ago\' +\%Y.\%m.\%d`/" > /dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  class { 'logstash::curator':
    keep_for_days  => '10',
  }

}
