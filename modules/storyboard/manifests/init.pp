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
  $serveradmin = "webmaster@${::fqdn}",
  $mysql_root_password,
  $mysql_password,
  # TODO(ruhe): replace with correct links once all the required bits pass code reviews
  $storyboard_git_source_repo = 'https://github.com/ruhe/storyboard.git',
  $storyboard_revision = 'infra',
  $storyboard_webclient_url = '127.0.0.1:8000/storyboard-web.tar.gz'
) {
  include apache
  include mysql::server::account_security
  include mysql::python
  include pip

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }

  mysql::db { 'storyboard':
    user     => 'storyboard',
    password => $mysql_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
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
    require     => Class['pip'],
    notify      => Exec['storyboard-reload'],
  }

  file { '/etc/storyboard':
    ensure => directory,
  }

  file { '/etc/storyboard/storyboard.conf':
    ensure  => present,
    owner   => 'storyboard',
    mode    => '0400',
    content => template('storyboard/storyboard.conf.erb'),
    require => [
      File['/etc/storyboard'],
      User['storyboard'],
    ],
    notify  => Exec['storyboard-reload'],
  }

  exec { 'migrate-stroryboard-db':
    command     => 'storyboard-db-manage --config-file /etc/storyboard/storyboard.conf upgrade head',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    required    => [
      File['/etc/storyboard/storyboard.conf'],
      Mysql::Db['storyboard'],
    ],
    refreshonly => true,
    subscribe   => Exec['install-storyboard'],
  }

  file { '/var/log/storyboard':
    ensure  => directory,
    owner   => 'storyboard',
    require => User['storyboard'],
  }

  file { '/etc/init.d/storyboard':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/storyboard/storyboard.init',
  }

  exec { 'storyboard-reload':
    command     => '/etc/init.d/storyboard reload',
    require     => File['/etc/init.d/storyboard'],
    refreshonly => true,
  }

  service { 'storyboard':
    ensure     => running,
    name       => 'storyboard',
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/storyboard'],
  }

  # START storyboard-webclient

  $tarball = 'storyboard-webclient.tar.gz'
  $unpack_target = '/root/tmp-storyboard-webclient'

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
    require => File[$unpack_target],
  }

  exec { 'save-webclient-tarball':
    command     => "mv /tmp/${tarball} /root",
    path        => '/bin:/usr/bin',
    subscribe   => Exec['unpack-webclient'],
    refreshonly => true,
  }

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
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'storyboard/storyboard.vhost.erb',
  }

  a2mod { 'proxy':
    ensure => present,
  }

  a2mod { 'proxy_http':
    ensure => present,
  }

}
