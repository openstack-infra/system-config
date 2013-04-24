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

  class { 'logstash::indexer':
    conf_template => 'openstack_project/logstash/indexer.conf.erb',
  }
  include logstash::elasticsearch
  include logstash::web

  package { 'redis-server':
    ensure => 'absent',
  }

  package { 'python3':
    ensure => 'present',
  }

  package { 'python3-zmq':
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

  cron { 'delete_old_es_indices':
    user        => 'root',
    hour        => '5',
    minute      => '0',
    command     => 'curl -sS -XDELETE "http://localhost:9200/logstash-`date -d \'last week\' +\%Y.\%m.\%d`/"',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'optimize_old_es_indices':
    user        => 'root',
    hour        => '5',
    minute      => '0',
    command     => 'curl -sS -XPOST "http://localhost:9200/logstash-`date -d yesterday +\%Y.\%m.\%d`/_optimize" -d \'max_num_segments=1\'',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }
}
