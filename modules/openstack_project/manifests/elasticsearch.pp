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
class openstack_project::elasticsearch (
  $sysadmins = []
) {
  $iptables_rule = '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s logstash.openstack.org -j ACCEPT'
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => $sysadmins,
  }

  include logstash::elasticsearch

  cron { 'delete_old_es_indices':
    user        => 'root',
    hour        => '5',
    minute      => '0',
    command     => 'curl -sS -XDELETE "http://localhost:9200/logstash-`date -d \'last week\' +\%Y.\%m.\%d`/" > /dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'optimize_old_es_indices':
    user        => 'root',
    hour        => '5',
    minute      => '0',
    command     => 'curl -sS -XPOST "http://localhost:9200/logstash-`date -d yesterday +\%Y.\%m.\%d`/_optimize?max_num_segments=2" > /dev/null',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }
}
