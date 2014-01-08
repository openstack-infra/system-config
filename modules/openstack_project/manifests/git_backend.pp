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
# Class to configure cgit on a CentOS node.
#
# == Class: openstack_project::git_backend
class openstack_project::git_backend (
  $vhost_name = $::fqdn,
  $sysadmins = [],
  $git_gerrit_ssh_key = '',
  $git_zuul_ssh_key = '',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $behind_proxy = false
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [4443, 8080, 29418],
    sysadmins                 => $sysadmins,
  }

  include jeepyb
  include pip

  class { '::cgit':
    vhost_name              => $vhost_name,
    ssl_cert_file           => '/etc/pki/tls/certs/git.openstack.org.pem',
    ssl_key_file            => '/etc/pki/tls/private/git.openstack.org.key',
    ssl_chain_file          => '/etc/pki/tls/certs/intermediate.pem',
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    behind_proxy            => $behind_proxy,
  }

  # We don't actually use these, but jeepyb requires them.
  $local_git_dir = '/var/lib/git'
  $ssh_project_key = ''

  file { '/etc/cgitrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/git/cgitrc'
  }

  file { '/home/cgit/.ssh/':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0700',
    require => User['cgit'],
  }

  file { '/home/cgit/.ssh/authorized_keys':
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0600',
    content => $git_gerrit_ssh_key,
    replace => true,
    require => File['/home/cgit/.ssh/']
  }

  file { '/home/cgit/projects.yaml':
    ensure  => present,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0444',
    content => template('openstack_project/review.projects.yaml.erb'),
    replace => true,
  }

  exec { 'create_cgitrepos':
    command     => 'create-cgitrepos',
    path        => '/bin:/usr/bin:/usr/local/bin',
    environment => [
      'SCRATCH_SUBPATH=zuul',
      'SCRATCH_OWNER=zuul',
      'SCRATCH_GROUP=zuul',
    ],
    require     => [
      File['/home/cgit/projects.yaml'],
      User['zuul'],
    ],
    subscribe   => File['/home/cgit/projects.yaml'],
    refreshonly => true,
  }

  class { 'selinux':
    mode => 'enforcing'
  }

  cron { 'mirror_repack':
    user        => 'cgit',
    weekday     => '0',
    hour        => '4',
    minute      => '7',
    command     => 'find /var/lib/git/ -not -path /var/lib/git/zuul -type d -name "*.git" -print -exec git --git-dir="{}" repack -afd \; -exec git --git-dir="{}" pack-refs --all \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => User['cgit'],
  }

  file { '/var/www/cgit/static/openstack.png':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack.png',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/favicon.ico':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/status/favicon.ico',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/openstack-page-bkg.jpg':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack-page-bkg.jpg',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/openstack.css':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/git/openstack.css',
    require => File['/var/www/cgit/static'],
  }

  file { '/usr/local/bin/commit-filter.sh':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/git/commit-filter.sh',
  }

  user { 'zuul':
    ensure     => present,
    home       => '/home/zuul',
    shell      => '/bin/bash',
    gid        => 'zuul',
    managehome => true,
    require    => Group['zuul'],
  }

  group { 'zuul':
    ensure => present,
  }

  file {'/home/zuul':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0755',
    require => User['zuul'],
  }

  file { '/var/lib/git/zuul':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0755',
    require => [
      User['zuul'],
      File['/var/lib/git'],
    ]
  }

  file { '/home/zuul/.ssh':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0700',
    require => User['zuul'],
  }

  file { '/home/zuul/.ssh/authorized_keys':
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0600',
    content => $git_zuul_ssh_key,
    replace => true,
    require => File['/home/zuul/.ssh']
  }

  cron { 'mirror_repack_zuul':
    user        => 'zuul',
    weekday     => '0',
    hour        => '4',
    minute      => '7',
    command     => 'find /var/lib/git/zuul -type d -name "*.git" -print -exec git --git-dir="{}" repack -afd \; -exec git --git-dir="{}" pack-refs --all \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => User['zuul'],
  }

}
