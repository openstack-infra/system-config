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
  $elasticsearch_nodes = [],
  $elasticsearch_clients = [],
  $discover_nodes = ['localhost'],
  $heap_size = '30g',
  $sysadmins = []
) {
  $iptables_nodes_rule = regsubst ($elasticsearch_nodes, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  $iptables_clients_rule = regsubst ($elasticsearch_clients, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  $iptables_rule = flatten([$iptables_nodes_rule, $iptables_clients_rule])
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => $sysadmins,
  }

  class { 'logstash::elasticsearch': }

  class { '::elasticsearch':
    es_template_config => {
      'index.store.compress.stored'          => true,
      'index.store.compress.tv'              => true,
      'indices.memory.index_buffer_size'     => '33%',
      'bootstrap.mlockall'                   => true,
      'gateway.recover_after_nodes'          => '5',
      'gateway.recover_after_time'           => '5m',
      'gateway.expected_nodes'               => '6',
      'discovery.zen.minimum_master_nodes'   => '4',
      'discovery.zen.ping.multicast.enabled' => false,
      'discovery.zen.ping.unicast.hosts'     => $discover_nodes,
    },
    heap_size          => $heap_size,
    version            => '0.90.9',
  }

  cron { 'delete_old_es_indices':
    user        => 'root',
    hour        => '2',
    minute      => '0',
    command     => 'curl -sS -XDELETE "http://localhost:9200/logstash-`date -d \'10 days ago\' +\%Y.\%m.\%d`/" > /dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'optimize_old_es_indices':
    ensure      => absent,
    user        => 'root',
    hour        => '13',
    minute      => '0',
    command     => 'curl -sS -XPOST "http://localhost:9200/logstash-`date -d yesterday +\%Y.\%m.\%d`/_optimize?max_num_segments=2" > /dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }
}
