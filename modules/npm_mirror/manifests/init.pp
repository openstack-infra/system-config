# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the 'License'); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: npm-mirror
#
# A class which installs an NPM package mirror on the provided system. Note
# that this will also kick off the replication, which might take some time.
#

class npm_mirror(
  $host = '127.0.0.1',
  $port = '5984',
  $admin_username = undef,
  $admin_password = undef,
) {

  package { 'couchdb':
      ensure => installed
  }

  package { 'curl':
      ensure => installed
  }

  user { 'couchdb':
    ensure  => 'present',
    require => Package['couchdb'],
  }

  group { 'couchdb':
    ensure  => 'present',
    require => Package['couchdb'],
  }

  service { 'couchdb':
    ensure  => 'running',
    enable  => true,
    require => Package['couchdb']
  }

  file { 'local.ini':
    ensure  => present,
    path    => '/etc/couchdb/local.ini',
    notify  => Service['couchdb'],
    owner   => 'couchdb',
    group   => 'couchdb',
    mode    => '0640',
    replace => true,
    require => [
      Package['couchdb'],
      User['couchdb'],
      Group['couchdb']
    ],
    content => template('npm-mirror/local.ini.erb'),
  }

  file { 'netrc':
    ensure  => present,
    path    => '/etc/couchdb/.netrc',
    owner   => 'couchdb',
    group   => 'couchdb',
    mode    => '0600',
    replace => true,
    require => [
      Package['couchdb'],
      User['couchdb'],
      Group['couchdb']
    ],
    content => template('npm-mirror/netrc.erb'),
  }

  file { 'replicate_npm':
    ensure  => present,
    path    => '/etc/couchdb/replicate_npm.json',
    owner   => 'couchdb',
    group   => 'couchdb',
    mode    => '0600',
    require => [
      Package['couchdb'],
      User['couchdb'],
      Group['couchdb']
    ],
    source  => 'puppet:///modules/npm-mirror/replicate_npm.json'
  }

  exec { 'wait_for_couchdb':
    path    => '/usr/local/bin:/usr/bin:/bin',
    require => Service['couchdb'],
    command => "sleep 5; curl http://${host}:${port}/ --silent --retry 10",
  }

  exec { 'ensure_database_exists':
    unless  => "curl --netrc-file /etc/couchdb/.netrc --output /dev/null --silent --head --fail http://localhost:${port}/registry",
    command => "curl --netrc-file /etc/couchdb/.netrc --silent -X PUT http://localhost:${port}/registry",
    path    => '/usr/local/bin:/usr/bin:/bin',
    require => [
      Exec['wait_for_couchdb'],
      File['netrc']
    ]
  }

  exec { 'start_replication':
    unless  => "curl --netrc-file /etc/couchdb/.netrc --output /dev/null --silent --head --fail http://localhost:${port}/_replicator/replicate_npm",
    command => "curl --netrc-file /etc/couchdb/.netrc --silent -d @/etc/couchdb/replicate_npm.json -X POST http://localhost:${port}/_replicator -H 'Content-Type: application/json'",
    path    => '/usr/local/bin:/usr/bin:/bin',
    require => [
      Exec['ensure_database_exists'],
      File['netrc'],
      File['replicate_npm']
    ]
  }
}