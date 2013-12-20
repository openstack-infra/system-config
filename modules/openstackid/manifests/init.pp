# Copyright 2013  OpenStack Foundation
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
# openstackid idp(sso-openid)
#
# == Class: openstackid
#
class openstackid (
  $git_source_repo = 'https://git.openstack.org/openstack-infra/openstackid',
  $site_admin_password = '',
  $mysql_host = '',
  $mysql_user = '',
  $mysql_password = '',
  $id_db_name = '',
  $ss_db_name = '',
  $redis_port = '',
  $redis_host = '',
  $vhost_name = $::fqdn,
  $robots_txt_source = '',
  $serveradmin = "webmaster@${::fqdn}",
  $canonicalweburl = "https://${::fqdn}/",
  $ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $httpd_acceptorthreads = '',
) {

  vcsrepo { '/opt/openstackid':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => $git_source_repo,
  }

  # we need PHP 5.4 or greather
  include apt
  apt::ppa { 'ppa:ondrej/php5-oldstable': }

  # php packages needed for openid server
  package {
    [
      'php5-common',
      'php5-curl',
      'php5-cli',
      'php5-json',
      'php5-mcrypt',
      'php5-mysql',
    ]:
    require => Exec[apt_update],
  }

  group { 'openstackid':
    ensure => present,
  }

  user { 'openstackid':
    ensure     => present,
    managehome => true,
    comment    => 'OpenStackID User',
    shell      => '/bin/bash',
    gid        => 'openstackid',
    require    => Group['openstackid'],
  }

  file { '/etc/openstackid':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/openstackid/database.php':
    ensure  => present,
    content => template('openstackid/database.php.erb'),
    owner   => 'root',
    group   => 'openstackid',
    mode    => '0640',
    require => [
      File['/etc/openstackid'],
      Group['openstackid'],
    ]
  }

  file { '/srv/openstackid':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/srv/openstackid/app':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/openstackid'],
  }

  file { '/srv/openstackid/app/config':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/openstackid/app'],
  }

  file { '/srv/openstackid/app/config/dev':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/openstackid/app/config'],
  }

  file { '/srv/openstackid/app/config/dev/database.php':
    ensure  => link,
    target  => '/etc/openstackid/database.php',
    require => [
      File['/srv/openstackid/app/config/dev'],
      File['/etc/openstackid/database.php'],
    ],
  }

  file { '/srv/openstackid/public':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/openstackid'],
  }

  include apache
  include apache::ssl
  include apache::php
  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => '/srv/openstackid/public',
    priority => '50',
    template => 'openstackid/vhost.erb',
    ssl      => true,
    require  => File['/srv/openstackid/public'],
  }
  a2mod { 'rewrite':
    ensure => present,
  }
  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
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

  if $robots_txt_source != '' {
    file { '/srv/openstackid/public/robots.txt':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => $robots_txt_source,
      require => File['/srv/openstackid/public'],
    }
  }

}
