# Copyright 2015 Hewlett-Packard Development Company, L.P.
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
# Class to configure hound
#
# == Class: openstack_project::hound
class openstack_project::hound (
  $vhost_name = $::fqdn,
  $sysadmins = [],
  $hound_datadir = '/home/hound/data',
  $serveradmin = "webmaster@${::fqdn}",
  $project_config_repo = '',
) {

  class { 'project_config':
    url  => $project_config_repo,
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }

  include jeepyb
  include logrotate
  include pip

  # We don't actually use these variables in this manifest, but jeepyb
  # requires them to exist.
  $local_git_dir = '/var/lib/git'
  $ssh_project_key = ''

  exec { 'create_hound_config':
    command     => 'create-hound-config',
    path        => '/bin:/usr/bin:/usr/local/bin',
    environment => "PROJECTS_YAML=${::project_config::jeepyb_project_file}",
    user        => 'hound',
    cwd         => '/home/hound',
    require     => [
      User['hound'],
      $::project_config::config_dir,
    ],
    subscribe   => $::project_config::config_dir,
    refreshonly => true,
  }

  package { 'golang':
    ensure => present,
  }

  user { 'hound':
    ensure     => present,
    home       => '/home/hound',
    shell      => '/bin/bash',
    gid        => 'hound',
    managehome => true,
    require    => Group['hound'],
  }

  group { 'hound':
    ensure => present,
  }

  file {'/home/hound':
    ensure  => directory,
    owner   => 'hound',
    group   => 'hound',
    mode    => '0755',
    require => User['hound'],
  }

  file { $hound_datadir:
    ensure  => 'directory',
    owner   => 'hound',
    group   => 'hound',
    require => User['hound'],
  }

  exec { 'install_hound':
    command     => 'go get github.com/etsy/hound/cmds/...',
    path        => '/bin:/usr/bin:/usr/local/bin',
    environment => 'GOPATH=/home/hound',
    cwd         => '/home/hound',
    creates     => '/home/hound/bin/houndd',
    user        => 'hound',
    timeout     => 600,
    require     => [
      User['hound'],
      Package['golang'],
      Exec['create_hound_config'],
    ]
  }

  service { 'hound':
    ensure  => running,
    hasrestart => true,
    require => [
      File['/etc/init.d/hound'],
      Exec['create_hound_config'],
      Exec['install_hound'],
    ],
    subscribe => Exec['create_hound_config'],
  }

  file { '/etc/init.d/hound':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/hound.init',
    notify  => Service['hound'],
    before  => Service['hound'],
  }

  logrotate::file { 'hound.log':
    ensure  => present,
    log     => '/var/log/hound.log',
    options => ['compress',
      'copytruncate',
      'delaycompress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
  }

  include ::apache

  a2mod { 'rewrite':
    ensure => present,
  }

  a2mod { 'proxy':
    ensure => present,
  }

  a2mod { 'proxy_http':
    ensure => present,
  }

  apache::vhost { $vhost_name:
    port        => 80,
    docroot     => 'MEANINGLESS ARGUMENT',
    priority    => '50',
    template    => 'openstack_project/hound.vhost.erb',
  }

}
