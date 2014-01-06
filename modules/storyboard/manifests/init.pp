# Copyright (c) 2014 Mirantis Inc.
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

# == Class: storyboard
#
class storyboard (
  $vhost_name = $::fqdn,
  $mysql_host,
  $mysql_password,
  $mysql_user,
  $storyboard_git_source_repo = 'https://git.openstack.org/cgit/openstack-infra/storyboard/',
  $storyboard_revision = 'master',
  $storyboard_webclient_url = 'http://tarballs.openstack.org/storyboard-webclient/storyboard-webclient-latest.tar.gz'
) {
  include apache
  include mysql::python
  include pip

  package { 'libapache2-mod-wsgi':
    ensure => present,
  }

  group { 'storyboard':
    ensure => present,
  }

  user { 'storyboard':
    ensure     => present,
    home       => '/home/storyboard',
    shell      => '/bin/bash',
    gid        => 'storyboard',
    managehome => true,
    require    => Group['storyboard'],
  }

  vcsrepo { '/opt/storyboard':
    ensure   => latest,
    provider => git,
    revision => $storyboard_revision,
    source   => $storyboard_git_source_repo,
  }

  exec { 'install-storyboard' :
    command     => 'pip install /opt/storyboard',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/storyboard'],
    notify      => Exec['storyboard-reload'],
    require     => Class['pip'],
  }

  file { '/etc/storyboard':
    ensure => directory,
  }

  file { '/etc/storyboard/storyboard.conf':
    ensure  => present,
    owner   => 'storyboard',
    mode    => '0400',
    content => template('storyboard/storyboard.conf.erb'),
    notify  => Exec['storyboard-reload'],
    require => [
      File['/etc/storyboard'],
      User['storyboard'],
    ],
  }

  exec { 'migrate-stroryboard-db':
    command     => 'storyboard-db-manage --config-file /etc/storyboard/storyboard.conf upgrade head',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Exec['install-storyboard'],
    require     => [
      File['/etc/storyboard/storyboard.conf'],
    ],
  }

  file { '/var/log/storyboard':
    ensure  => directory,
    owner   => 'storyboard',
    require => User['storyboard'],
  }

  exec { 'storyboard-reload':
    command     => 'touch /usr/local/lib/python2.7/dist-packages/storyboard/api/app.wsgi',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
  }

  # START storyboard-webclient

  $tarball = 'storyboard-webclient.tar.gz'
  $unpack_target = '/tmp/storyboard-webclient-unpack'

  file { '/var/lib/storyboard':
    ensure  => directory,
    owner   => 'storyboard',
    group   => 'storyboard',
  }

  file { '/var/lib/storyboard/www':
    ensure  => directory,
    purge   => true,
    require => File['/var/lib/storyboard'],
  }

  exec { 'wget-webclient':
    command => "wget ${storyboard_webclient_url} -O /tmp/${tarball}",
    path    => '/bin:/usr/bin',
  }

  file { $unpack_target:
    ensure  => directory,
    purge   => true,
    recurse => true,
    force   => true,
  }

  exec { 'unpack-webclient':
    command => "tar xzf /tmp/${tarball}",
    path    => '/bin:/usr/bin',
    cwd     => $unpack_target,
    unless  => "cmp /tmp/${tarball} /root/${tarball} > /dev/null 2>&1",
    require => [
      File[$unpack_target],
      Exec['wget-webclient'],
    ],
  }

  exec { 'save-webclient-tarball':
    command     => "mv /tmp/${tarball} /root",
    path        => '/bin:/usr/bin',
    subscribe   => Exec['unpack-webclient'],
    refreshonly => true,
  }

  # TODO(mordred): race condition here - replace with a symlink move
  exec { 'install-webclient':
    command     => "rm -rf /var/lib/storyboard/www/*; mv ${unpack_target}/*/* /var/lib/storyboard/www",
    path        => '/bin:/usr/bin',
    subscribe   => Exec['unpack-webclient'],
    refreshonly => true,
    require     => [
      File['/var/lib/storyboard/www'],
      File[$unpack_target],
    ],
  }

  # END storyboard-webclient

  apache::vhost { $vhost_name:
    port     => 80,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'storyboard/storyboard.vhost.erb',
    require  => Package['libapache2-mod-wsgi'],
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
