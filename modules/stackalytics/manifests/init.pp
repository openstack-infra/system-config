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
  $stackalytics_git_source_repo = 'https://git.openstack.org/sourceforce/stackalytics/',
  $stackalytics_revision = 'master',
  $default_data_uri = 'https://git.openstack.org/cgit/stackforge/stackalytics/plain/etc/default_data.json',
  $corrections_uri = 'https://git.openstack.org/cgit/stackforge/stackalytics/plain/etc/corrections.json',
  $review_uri = 'gerrit://review.openstack.org',
  $gerrit_ssh_user = 'stackalytics',
  $program_list_uri = 'https://git.openstack.org/cgit/openstack/governance/plain/reference/programs.yaml',
) {

  include apache
  include pip

  package { 'libapache2-mod-wsgi':
    ensure => present,
  }

  class { 'memcached':
    max_memory => 2048,
    listen_ip  => '127.0.0.1',
    tcp_port   => 11000,
    udp_port   => 11000,
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
    ensure  => present,
    content => $stackalytics_ssh_private_key,
    mode    => '0400',
    owner   => 'stackalytics',
    group   => 'stackalytics',
    require => File['/home/stackalytics/.ssh'],
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

  # install-data=/tmp is to prevent pip from installing/overwriting config
  # files. Can be removed when https://review.openstack.org/98637 lands
  exec { 'install-stackalytics':
    command     => 'pip install --install-option="--install-data=/tmp" /opt/stackalytics',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/stackalytics'],
    notify      => Exec['process-stackalytics'],
    require     => Class['pip'],
  }

  # Should this run in a cron instead? I have a feeling sometimes this is
  # going to take a very long time.
  exec { 'process-stackalytics':
    command     => 'stackalytics-processor',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/stackalytics'],
    notify      => Exec['stackalytics-reload'],
    require     => Exec['install-stackalytics'],
  }

  file { '/etc/stackalytics':
    ensure => directory,
  }

  file { '/etc/stackalytics/stackalytics.conf':
    ensure  => present,
    owner   => 'stackalytics',
    mode    => '0400',
    content => template('stackalytics/stackalytics.conf.erb'),
    notify  => Exec['stackalytics-reload'],
    require => [
      File['/etc/stackalytics'],
      User['stackalytics'],
    ],
  }

  # This can be removed when https://review.openstack.org/98642 lands
  file { '/usr/local/lib/python2.7/dist-packages/stackalytics/dashboard/web.wsgi':
    ensure  => present,
    owner   => 'stackalytics',
    mode    => '0400',
    source  => 'puppet:///modules/stackalytics/web.wsgi',
    require => [
      Exec['install-stackalytics'],
      User['stackalytics'],
    ],
  }

  exec { 'stackalytics-reload':
    command     => 'touch /usr/local/lib/python2.7/dist-packages/dashboard/web.wsgi',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
  }

  apache::vhost { $vhost_name:
    port     => 80,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'stackalytics/stackalytics.vhost.erb',
    require  => Package['libapache2-mod-wsgi'],
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
    require => Package['libapache2-mod-wsgi'],
  }

}
