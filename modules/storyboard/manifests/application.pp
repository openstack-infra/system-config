# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: storyboard::application
#
# This module installs the storyboard webclient and the api onto the current
# host. If storyboard::cert is defined, it will use a https vhost, otherwise
# it'll just use http.
#
class storyboard::application (

  # Installation parameters
  $www_root            = '/var/lib/storyboard/www',
  $server_admin        = undef,
  $hostname            = $::fqdn,

  # storyboard.conf parameters
  $access_token_ttl    = 3600,
  $refresh_token_ttl   = 604800,
  $openid_url          = 'https://login.launchpad.net/+openid',
  $mysql_host          = 'localhost',
  $mysql_port          = 3306,
  $mysql_database      = 'storyboard',
  $mysql_user          = 'storyboard',
  $mysql_user_password = 'changeme',
) {

  # Dependencies
  require storyboard::params
  include apache
  include apache::mod::wsgi

  class { 'python':
    pip => true,
    dev => true,
  }
  include python::install
  include mysql::python

  # Configure the StoryBoard API
  file { '/etc/storyboard.conf':
    ensure  => present,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    mode    => '0400',
    content => template('storyboard/storyboard.conf.erb'),
    notify  => Service['httpd'],
    require => Class['apache::params'],
  }

  # Download the latest StoryBoard Source
  vcsrepo { '/opt/storyboard':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/storyboard/',
  }

  # Run pip
  exec { 'install-storyboard' :
    command     => 'pip install /opt/storyboard',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/storyboard'],
    notify      => Service['httpd'],
    require     => [
      Class['apache::params'],
      Class['python::install'],
    ]
  }

  # Create the root dir
  file { '/var/lib/storyboard':
    ensure => directory,
    owner  => $storyboard::params::user,
    group  => $storyboard::params::group,
  }

  # Create the log dir
  file { '/var/log/storyboard':
    ensure  => directory,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
  }

  # Install the wsgi app
  file { '/var/lib/storyboard/storyboard.wsgi':
    source  => '/opt/storyboard/storyboard/api/app.wsgi',
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    require => [
      File['/var/lib/storyboard'],
      Exec['install-storyboard'],
    ],
    notify  => Service['httpd'],
  }

  # Migrate the database
  exec { 'migrate-storyboard-db':
    command     => 'storyboard-db-manage --config-file /etc/storyboard.conf upgrade head',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => [
      Exec['install-storyboard'],
      File['/etc/storyboard.conf'],
    ],
    require     => [
      Class['mysql::python'],
      File['/etc/storyboard.conf'],
    ],
    notify      => Service['httpd'],
  }

  # Download the latest storyboard-webclient
  puppi::netinstall { 'storyboard-webclient':
    url             => 'http://tarballs.openstack.org/storyboard-webclient/storyboard-webclient-latest.tar.gz',
    destination_dir => '/opt/storyboard-webclient',
    extracted_dir   => 'dist',
  }

  # Copy the downloaded source into the configured www_root
  file { $www_root:
    ensure      => directory,
    owner       => $storyboard::params::user,
    group       => $storyboard::params::group,
    require     => Puppi::Netinstall['storyboard-webclient'],
    source      => '/opt/storyboard-webclient/dist',
    recurse     => true,
    purge       => true,
    force       => true,
    notify      => Service['httpd'],
  }

  # Are we setting up TLS or non-TLS?
  if defined(Class['storyboard::cert']) {
    # Set up storyboard as HTTPS
    apache::vhost { $hostname:
      port     => 443,
      docroot  => $www_root,
      priority => '50',
      template => 'storyboard/storyboard_https.vhost.erb',
      ssl      => true,
    }
  } else {
    # Set up storyboard as HTTPS
    apache::vhost { $hostname:
      port     => 80,
      docroot  => $www_root,
      priority => '50',
      template => 'storyboard/storyboard_http.vhost.erb',
      ssl      => false,
    }
  }
}