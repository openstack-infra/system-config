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

  vcsrepo { '/opt/subunit2sql':
    ensure   => present,
    provider => git,
    source   => 'git://git.openstack.org/openstack-infra/subunit2sql',
    revision => '0.2.0',
  }

  exec { 'install_subunit2sql':
    command     => 'pip install /opt/subunit2sql',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/subunit2sql'],
    require     => [
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
    source  => 'puppet:///modules/log_processor/subunit-gearman-worker.py',
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
