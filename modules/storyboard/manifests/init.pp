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
  $projects_file,
  $ssl_cert_file,
  $ssl_key_file,
  $ssl_chain_file,
  $storyboard_git_source_repo = 'https://git.openstack.org/openstack-infra/storyboard/',
  $storyboard_revision = 'master',
  $storyboard_webclient_url = 'http://tarballs.openstack.org/storyboard-webclient/storyboard-webclient-latest.tar.gz',
  $serveradmin = "webmaster@${::fqdn}",
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = ''
) {
  include apache
  include mysql::python
  include pip

  package { 'libapache2-mod-wsgi':
    ensure => present,
  }

  package { 'curl':
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

  file { '/etc/storyboard/projects.yaml':
    ensure  => present,
    owner   => 'storyboard',
    mode    => '0400',
    source  => $projects_file,
    replace => true,
    require => [
      File['/etc/storyboard'],
      User['storyboard'],
    ],
  }

  exec { 'migrate-storyboard-db':
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

  file { '/var/lib/storyboard':
    ensure  => directory,
    owner   => 'storyboard',
    group   => 'storyboard',
  }

  # Using -z here to only download when the tarball has changed.
  exec { 'get-webclient':
    command => "curl ${storyboard_webclient_url} -z ./${tarball} -o ${tarball}",
    path    => '/bin:/usr/bin',
    cwd     => '/var/lib/storyboard',
    require => [
      File['/var/lib/storyboard'],
      Package['curl'],
    ]
  }

  exec { 'unpack-webclient':
    command => "tar -xzf ${tarball}",
    path    => '/bin:/usr/bin',
    cwd     => '/var/lib/storyboard',
    require => Exec['get-webclient'],
  }

  file { '/var/lib/storyboard/www':
    ensure  => directory,
    owner   => 'storyboard',
    group   => 'storyboard',
    require => Exec['unpack-webclient'],
    source  => '/var/lib/storyboard/dist',
    recurse => true,
    purge   => true,
    force   => true
  }

  # END storyboard-webclient

  apache::vhost { $vhost_name:
    port     => 80,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'storyboard/storyboard.vhost.erb',
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

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }
}
