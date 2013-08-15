# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2012 Antoine "hashar" Musso
# Copyright 2012 Wikimedia Foundation Inc.
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

# == Class: nodepool
#
class nodepool (
  $mysql_root_password,
  $mysql_password,
  $nodepool_ssh_private_key = '',
  $git_source_repo = 'https://git.openstack.org/openstack-infra/nodepool',
  $revision = 'master',
  $statsd_host = ''
) {

  package { 'sqlite3':
    ensure => present,
  }

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }

  include mysql::server::account_security
  include mysql::python

  mysql::db { 'nodepool':
    user     => 'nodepool',
    password => $mysql_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'latin1',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
  
  user { 'nodepool':
    ensure     => present,
    home       => '/home/nodepool',
    shell      => '/bin/bash',
    gid        => 'nodepool',
    managehome => true,
    require    => Group['nodepool'],
  }

  group { 'nodepool':
    ensure => present,
  }

  vcsrepo { '/opt/nodepool':
    ensure   => latest,
    provider => git,
    revision => $revision,
    source   => $git_source_repo,
  }

  exec { 'install_nodepool' :
    command     => 'python setup.py install',
    cwd         => '/opt/nodepool',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/nodepool'],
    require     => Class['pip'],
  }

  file { '/etc/nodepool':
    ensure => directory,
  }

  file { '/etc/default/nodepool':
    ensure  => present,
    mode    => '0444',
    content => template('nodepool/nodepool.default.erb'),
  }

  file { '/var/log/nodepool':
    ensure  => directory,
    owner   => 'nodepool',
    require => User['nodepool'],
  }

  file { '/var/run/nodepool':
    ensure  => directory,
    owner   => 'nodepool',
    group   => 'nodepool',
    require => User['nodepool'],
  }

  file { '/home/nodepool/.ssh':
    ensure  => directory,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0500',
    require => User['nodepool'],
  }

  file { '/home/nodepool/.ssh/id_rsa':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0400',
    require => File['/home/nodepool/.ssh'],
    content => $nodepool_ssh_private_key,
  }

  file { '/home/nodepool/.ssh/config':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0440',
    require => File['/home/nodepool/.ssh'],
    source  => 'puppet:///modules/nodepool/ssh.config',
  }

  file { '/etc/nodepool/logging.conf':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0444',
    source  => 'puppet:///modules/nodepool/logging.conf',
    notify  => Service['nodepool'],
  }

  file { '/etc/init.d/nodepool':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/nodepool/nodepool.init',
  }

  service { 'nodepool':
    name       => 'nodepool',
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/nodepool'],
  }
}
