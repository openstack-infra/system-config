# Copyright 2014 Hewlett-Packard Development Company, L.P.
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
# == Class: stackalytics
#
class stackalytics (
  $stackalytics_ssh_private_key,
  $vhost_name = $::fqdn,
  $stackalytics_git_source_repo = 'https://git.openstack.org/stackforge/stackalytics/',
  $stackalytics_revision = 'master',
  $default_data_uri = 'https://git.openstack.org/cgit/stackforge/stackalytics/plain/etc/default_data.json',
  $corrections_uri = 'https://git.openstack.org/cgit/stackforge/stackalytics/plain/etc/corrections.json',
  $review_uri = 'gerrit://review.openstack.org',
  $git_base = 'git://git.openstack.org',
  $gerrit_ssh_user = 'stackalytics',
  $program_list_uri = 'https://git.openstack.org/cgit/openstack/governance/plain/reference/programs.yaml',
  $memcached_port = '11211',
) {

  include apache
  include pip

  package { $::apache::params::mod_wsgi_package:
    ensure => present,
  }

  class { 'memcached':
    max_memory => 2048,
    listen_ip  => '127.0.0.1',
    tcp_port   => $memcached_port,
    udp_port   => $memcached_port,
  }

  group { 'stackalytics':
    ensure => present,
  }

  user { 'stackalytics':
    ensure     => present,
    home       => '/home/stackalytics',
    shell      => '/bin/bash',
    gid        => 'stackalytics',
    managehome => true,
    require    => Group['stackalytics'],
  }

  file { '/home/stackalytics/.ssh':
    ensure  => directory,
    mode    => '0500',
    owner   => 'stackalytics',
    group   => 'stackalytics',
    require => User['stackalytics'],
  }

  file { '/home/stackalytics/.ssh/id_rsa':
    ensure    => present,
    content   => $stackalytics_ssh_private_key,
    mode      => '0400',
    owner     => 'stackalytics',
    group     => 'stackalytics',
    require   => File['/home/stackalytics/.ssh'],
  }

  file { '/var/lib/git':
    ensure  => directory,
    owner   => 'stackalytics',
    group   => 'stackalytics',
    mode    => '0644',
    require => User['stackalytics'],
  }

  vcsrepo { '/opt/stackalytics':
    ensure   => latest,
    provider => git,
    revision => $stackalytics_revision,
    source   => $stackalytics_git_source_repo,
  }

  exec { 'install-stackalytics':
    command     => 'pip install /opt/stackalytics',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/stackalytics'],
    notify      => Exec['stackalytics-reload'],
    require     => Class['pip'],
  }

  cron { 'process_stackalytics':
    user        => 'stackalytics',
    hour        => '*/4',
    command     => 'stackalytics-processor',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => Exec['install-stackalytics'],
  }

  file { '/etc/stackalytics':
    ensure => directory,
  }

  file { '/etc/stackalytics/stackalytics.conf':
    ensure  => present,
    owner   => 'stackalytics',
    mode    => '0444',
    content => template('stackalytics/stackalytics.conf.erb'),
    notify  => Exec['stackalytics-reload'],
    require => [
      File['/etc/stackalytics'],
      User['stackalytics'],
    ],
  }

  exec { 'stackalytics-reload':
    command     => 'touch /usr/local/lib/python2.7/dist-packages/stackalytics/dashboard/web.wsgi',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
  }

  apache::vhost { $vhost_name:
    port     => 80,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'stackalytics/stackalytics.vhost.erb',
    require  => Package[$::apache::params::mod_wsgi_package],
    ssl      => true,
  }

  a2mod { 'proxy':
    ensure => present,
  }

  a2mod { 'proxy_http':
    ensure => present,
  }

  a2mod {'wsgi':
    ensure  => present,
    require => Package[$::apache::params::mod_wsgi_package],
  }

}
