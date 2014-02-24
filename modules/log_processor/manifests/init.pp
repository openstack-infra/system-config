# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2013 OpenStack Foundation
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

# == Class: log_processor
#
class log_processor (
) {
  package { 'python-daemon':
    ensure => present,
  }

  package { 'python-zmq':
    ensure => present,
  }

  package { 'python-yaml':
    ensure => present,
  }

  package { 'crm114':
    ensure => present,
  }

  include pip
  package { 'gear':
    ensure   => latest,
    provider => 'pip',
    require  => Class['pip'],
  }

  package { 'statsd':
    ensure   => latest,
    provider => 'pip',
    require  => Class['pip'],
  }

  file { '/var/lib/crm114':
    ensure  => directory,
    owner   => 'logstash',
    group   => 'logstash',
    require => User['logstash'],
  }

  file { '/usr/local/bin/classify-log.crm':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/log_processor/classify-log.crm',
    require => [
      Package['crm114'],
    ],
  }

  file { '/usr/local/bin/log-gearman-client.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/log_processor/log-gearman-client.py',
    require => [
      Package['python-daemon'],
      Package['python-zmq'],
      Package['python-yaml'],
      Package['gear'],
    ],
  }

  file { '/usr/local/bin/log-gearman-worker.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/log_processor/log-gearman-worker.py',
    require => [
      Package['python-daemon'],
      Package['python-zmq'],
      Package['python-yaml'],
      Package['gear'],
    ],
  }
}
