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
  $id_mysql_host = '',
  $id_mysql_user = '',
  $id_mysql_password = '',
  $id_db_name = '',
  $ss_mysql_host = '',
  $ss_mysql_user = '',
  $ss_mysql_password = '',
  $ss_db_name = '',
  $redis_port = '',
  $redis_host = '',
  $redis_password = '',
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
  $id_log_error_to_email = '',
  $id_log_error_from_email = '',
  $id_environment = 'dev',
  $id_hostname = $::fqdn,
  $id_recaptcha_public_key = '',
  $id_recaptcha_private_key = '',
  $id_recaptcha_template = '',
) {

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

  file { '/etc/openstackid/log.php':
      ensure  => present,
      content => template('openstackid/log.php.erb'),
      owner   => 'root',
      group   => 'openstackid',
      mode    => '0640',
      require => [
        File['/etc/openstackid'],
        Group['openstackid'],
      ]
  }

  file { '/etc/openstackid/recaptcha.php':
        ensure  => present,
        content => template('openstackid/recaptcha.php.erb'),
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

  file { '/srv/openstackid/bootstrap':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/openstackid'],
  }

  file { '/srv/openstackid/bootstrap/start.php':
        ensure  => present,
        content => template('openstackid/start.php.erb'),
        owner   => 'root',
        group   => 'openstackid',
        mode    => '0640',
        require => [
          File['/srv/openstackid/bootstrap'],
          Group['openstackid'],
        ]
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

  file { '/srv/openstackid/app/config/packages':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/srv/openstackid/app/config'],
  }

  file { '/srv/openstackid/app/config/packages/greggilbert':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/srv/openstackid/app/config/packages'],
  }

  file { '/srv/openstackid/app/config/packages/greggilbert/recaptcha':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/srv/openstackid/app/config/packages/greggilbert'],
  }

  file { "/srv/openstackid/app/config/packages/greggilbert/recaptcha/${id_environment}":
          ensure  => directory,
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          require => File['/srv/openstackid/app/config/packages/greggilbert/recaptcha'],
  }

  file { "/srv/openstackid/app/config/packages/greggilbert/recaptcha/${id_environment}/config.php":
      ensure  => link,
      target  => '/etc/openstackid/recaptcha.php',
      require => [
        File["/srv/openstackid/app/config/packages/greggilbert/recaptcha/${id_environment}"],
        File['/etc/openstackid/recaptcha.php'],
      ],
  }

  file { "/srv/openstackid/app/config/${id_environment}":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/srv/openstackid/app/config'],
  }

  file { "/srv/openstackid/app/config/${id_environment}/database.php":
    ensure  => link,
    target  => '/etc/openstackid/database.php',
    require => [
      File["/srv/openstackid/app/config/${id_environment}"],
      File['/etc/openstackid/database.php'],
    ],
  }

  file { "/srv/openstackid/app/config/${id_environment}/log.php":
      ensure  => link,
      target  => '/etc/openstackid/log.php',
      require => [
        File["/srv/openstackid/app/config/${id_environment}"],
        File['/etc/openstackid/log.php'],
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
