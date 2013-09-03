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
  $elasticsearch_nodes = [],
  $discover_node = 'elasticsearch.openstack.org',
  $sysadmins = []
) {
  $iptables_rule = regsubst ($elasticsearch_nodes, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22],
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => $sysadmins,
  }

  class { 'logstash::indexer':
    conf_template => 'openstack_project/logstash/indexer.conf.erb',
  }

  package { 'python-daemon':
    ensure => present,
  }

  package { 'python-zmq':
    ensure => present,
  }

  package { 'python-yaml':
    ensure => present,
  }

  include pip
  package { 'gear':
    ensure   => latest,
    provider => 'pip',
    require  => Class['pip'],
  }

  file { '/usr/local/bin/log-gearman-worker.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/logstash/log-gearman-worker.py',
    require => [
      Package['python-daemon'],
      Package['python-zmq'],
      Package['python-yaml'],
      Package['gear'],
    ],
  }

  file { '/etc/logstash/jenkins-log-worker.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }

  file { '/etc/init.d/jenkins-log-worker':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.init',
    require => [
      File['/usr/local/bin/log-gearman-worker.py'],
      File['/etc/logstash/jenkins-log-worker.yaml'],
    ],
  }

  service { 'jenkins-log-worker':
    enable     => true,
    hasrestart => true,
    subscribe  => File['/etc/logstash/jenkins-log-worker.yaml'],
    require    => [
      Class['logstash::indexer'],
      File['/etc/init.d/jenkins-log-worker'],
    ],
  }

  include logrotate
  logrotate::file { 'log-worker-debug.log':
    log     => '/var/log/logstash/log-worker-debug.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service['jenkins-log-worker'],
  }
}
