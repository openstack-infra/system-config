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
  $statsd_host = '',
  $vhost_name = $::fqdn,
  $image_log_document_root = '/var/log/nodepool/image',
  $enable_image_log_via_http = false,
  $environment = {},
  # enable sudo for nodepool user. Useful for using dib with nodepool
  $sudo = true,
  $scripts_dir = '',
  $elements_dir = '',
) {

  # needed by python-keystoneclient, has system bindings
  # Zuul and Nodepool both need it, so make it conditional
  if ! defined(Package['python-lxml']) {
    package { 'python-lxml':
      ensure => present,
    }
  }

  # required by the nodepool diskimage-builder element scripts
  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
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
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }

  $packages = [
    'build-essential',
    'libffi-dev',
    'libssl-dev',
    'kpartx',
    'qemu-utils',
    'libgmp-dev',         # transitive dep of paramiko
    # debootstrap is needed for building Debian images
    'debootstrap',
  ]

  package { $packages:
    ensure => present,
  }

  file { '/etc/mysql/conf.d/max_connections.cnf':
    ensure  => present,
    content => "[server]\nmax_connections = 8192\n",
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
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

  package { 'diskimage-builder':
    ensure   => latest,
    provider => pip,
    require  => [
      Class['pip'],
      Package['python-yaml'],
    ],
  }

  include pip
  exec { 'install_nodepool' :
    command     => 'pip install /opt/nodepool',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/nodepool'],
    require     => [
      Class['pip'],
      Package['build-essential'],
      Package['libffi-dev'],
      Package['libssl-dev'],
      Package['python-lxml'],
      Package['libgmp-dev'],
    ],
  }

  file { '/etc/nodepool':
    ensure => directory,
  }

  if ($scripts_dir != '') {
    file { '/etc/nodepool/scripts':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      recurse => true,
      purge   => true,
      force   => true,
      require => File['/etc/nodepool'],
      source  => $scripts_dir,
    }
  }

  if ($elements_dir != '') {
    file { '/etc/nodepool/elements':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      recurse => true,
      purge   => true,
      force   => true,
      require => File['/etc/nodepool'],
      source  => $elements_dir
    }
  }

  file { '/etc/default/nodepool':
    ensure  => present,
    content => template('nodepool/nodepool.default.erb'),
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
  }

  # used for storage of d-i-b images in non-ephemeral partition
  file { '/opt/nodepool_dib':
    ensure  => directory,
    mode    => '0755',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => User['nodepool'],
  }

  # used for storage of d-i-b cached data
  file { '/opt/dib_cache':
    ensure  => directory,
    mode    => '0755',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => User['nodepool'],
  }

  # used as TMPDIR during d-i-b image builds
  file { '/opt/dib_tmp':
    ensure  => directory,
    mode    => '0755',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => User['nodepool'],
  }

  file { '/var/log/nodepool':
    ensure  => directory,
    mode    => '0755',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => User['nodepool'],
  }

  file { '/var/run/nodepool':
    ensure  => directory,
    mode    => '0755',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => User['nodepool'],
  }

  file { '/home/nodepool/.ssh':
    ensure  => directory,
    mode    => '0500',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => User['nodepool'],
  }

  file { '/home/nodepool/.ssh/id_rsa':
    ensure  => present,
    content => $nodepool_ssh_private_key,
    mode    => '0400',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => File['/home/nodepool/.ssh'],
  }

  file { '/home/nodepool/.ssh/config':
    ensure  => present,
    source  => 'puppet:///modules/nodepool/ssh.config',
    mode    => '0440',
    owner   => 'nodepool',
    group   => 'nodepool',
    require => File['/home/nodepool/.ssh'],
  }

  file { '/etc/nodepool/logging.conf':
    ensure  => present,
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => template('nodepool/nodepool.logging.conf.erb'),
  }

  file { '/etc/init.d/nodepool':
    ensure => present,
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/nodepool/nodepool.init',
  }

  service { 'nodepool':
    name       => 'nodepool',
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/nodepool'],
  }

  if $enable_image_log_via_http == true {
    # Setup apache for image log access
    include apache

    apache::vhost { $vhost_name:
      port     => 80,
      priority => '50',
      docroot  => 'MEANINGLESS_ARGUMENT',
      template => 'nodepool/nodepool-log.vhost.erb',
    }

    if $image_log_document_root != '/var/log/nodepool' {
      file { $image_log_document_root:
        ensure   => directory,
        mode     => '0755',
        owner    => 'nodepool',
        group    => 'nodepool',
        require  => [
          User['nodepool'],
          File['/var/log/nodepool'],
        ],
      }
    }
  }

  if $sudo == true {
    $sudo_file_ensure = present
  }
  else {
    $sudo_file_ensure = absent
  }
  file { '/etc/sudoers.d/nodepool-sudo':
    ensure => $sudo_file_ensure,
    source => 'puppet:///modules/nodepool/nodepool-sudo.sudo',
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
  }
}
