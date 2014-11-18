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

# == Class: subunit2sql
#
class subunit2sql (
) {
  include pip

  package {'python-mysqldb':
    ensure   => present,
  }

  package {'python-psycopg2':
    ensure   => present,
  }

  package { 'python-subunit':
    ensure   => latest,
    provider => 'pip',
    require  => Class['pip'],
  }

  package { 'subunit2sql':
    ensure   => latest,
    provider => 'pip',
    require  => [
      Class['pip'],
      Package['python-mysqldb'],
      Package['python-psycopg2']
    ],
  }

  package { 'testtools':
    ensure   => latest,
    provider => 'pip',
    require  => Class['pip'],
  }

  if ! defined(Package['python-daemon']) {
    package { 'python-daemon':
      ensure => present,
    }
  }

  if ! defined(Package['python-zmq']) {
    package { 'python-zmq':
      ensure => present,
    }
  }

  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  if ! defined(Package['gear']) {
    package { 'gear':
      ensure   => latest,
      provider => 'pip',
      require  => Class['pip'],
    }
  }

  if ! defined(Package['statsd']) {
    package { 'statsd':
      ensure   => latest,
      provider => 'pip',
      require  => Class['pip']
    }
  }

  file { '/usr/local/bin/subunit-gearman-worker.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/subunit2sql/subunit-gearman-worker.py',
    require => [
      Package['python-daemon'],
      Package['python-zmq'],
      Package['python-yaml'],
      Package['gear'],
      Package['subunit2sql'],
      Package['python-subunit'],
      Package['testtools']
    ],
  }
}
