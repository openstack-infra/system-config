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
  $elasticsearch_masters = [],
  $gearman_workers = [],
  $sysadmins = []
) {
  $iptables_es_rule = regsubst ($elasticsearch_masters, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
  $iptables_gm_rule = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')
  $iptables_rule = flatten([$iptables_es_rule, $iptables_gm_rule])
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => $sysadmins,
  }

  class { 'logstash::web':
    frontend           => 'kibana',
    elasticsearch_host => 'elasticsearch.openstack.org',
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

  file { '/usr/local/bin/log-gearman-client.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/logstash/log-gearman-client.py',
    require => [
      Package['python-daemon'],
      Package['python-zmq'],
      Package['python-yaml'],
      Package['gear'],
    ],
  }

  file { '/etc/logstash/jenkins-log-client.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/logstash/jenkins-log-client.yaml',
  }

  file { '/etc/init.d/jenkins-log-client':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/logstash/jenkins-log-client.init',
    require => [
      File['/usr/local/bin/log-gearman-client.py'],
      File['/etc/logstash/jenkins-log-client.yaml'],
    ],
  }

  service { 'jenkins-log-client':
    enable     => true,
    hasrestart => true,
    subscribe  => File['/etc/logstash/jenkins-log-client.yaml'],
    require    => File['/etc/init.d/jenkins-log-client'],
  }
}
