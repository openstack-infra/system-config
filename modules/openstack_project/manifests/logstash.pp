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
# Logstash indexer server glue class.
#
class openstack_project::logstash (
  $redis_password,
  $sysadmins = []
) {
  # List of rules allowing logstash agents to communicate with redis on
  # logstash.openstack.org.
  $ip_rules = [
    '-m state --state NEW -m tcp -p tcp --dport 6379 -s logstash.openstack.org -j ACCEPT',
  ]

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    iptables_rules4           => $ip_rules,
    iptables_rules6           => $ip_rules,
    sysadmins                 => $sysadmins,
  }

  class { 'logstash::agent':
    conf_template  => 'openstack_project/logstash/agent.conf.erb',
    redis_password => $redis_password,
  }
  class { 'logstash::indexer':
    conf_template  => 'openstack_project/logstash/indexer.conf.erb',
    redis_password => $redis_password,
  }
  class { 'logstash::redis':
    redis_password => $redis_password,
  }
  include logstash::elasticsearch
  include logstash::web
}
