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
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  class { 'logstash::agent':
    conf_template => 'openstack_project/logstash/agent.conf.erb',
  }
  class { 'logstash::indexer':
    conf_template => 'openstack_project/logstash/indexer.conf.erb',
  }
  include logstash::redis
  include logstash::elasticsearch
  include logstash::web

  package { 'python3':
    ensure => 'present',
  }

  file { '/usr/local/bin/log-pusher.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/logstash/log-pusher.py',
    require => Package['python3'],
  }
}
