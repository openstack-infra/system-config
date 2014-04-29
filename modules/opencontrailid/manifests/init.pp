# Copyright 2013  OpenContrail Foundation
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
# opencontrailid idp(sso-openid)
#
# == Class: opencontrailid
#
class opencontrailid (
  $git_source_repo = 'https://git.opencontrail.org/opencontrail-infra/opencontrailid',
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

  # php packages needed for openid server
  $php5_packages = [
      'php5-common',
      'php5-curl',
      'php5-cli',
      'php5-json',
      'php5-mcrypt',
      'php5-mysql',
    ]

  package { $php5_packages:
    require => Exec[apt_update],
  }

  group { 'opencontrailid':
    ensure => present,
  }

  user { 'opencontrailid':
    ensure     => present,
    managehome => true,
    comment    => 'OpenContrailID User',
    shell      => '/bin/bash',
    gid        => 'opencontrailid',
    require    => Group['opencontrailid'],
  }

  file { '/etc/opencontrailid':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/opencontrailid/database.php':
    ensure  => present,
    content => template('opencontrailid/database.php.erb'),
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    require => [
      File['/etc/opencontrailid'],
    ]
  }

  file { '/etc/opencontrailid/log.php':
      ensure  => present,
      content => template('opencontrailid/log.php.erb'),
      owner   => 'root',
      group   => 'www-data',
      mode    => '0640',
      require => [
        File['/etc/opencontrailid'],
      ]
  }

  file { '/etc/opencontrailid/environment.php':
      ensure  => present,
      content => template('opencontrailid/environment.php.erb'),
      owner   => 'root',
      group   => 'www-data',
      mode    => '0640',
      require => [
        File['/etc/opencontrailid'],
      ]
  }

  file { '/etc/opencontrailid/recaptcha.php':
        ensure  => present,
        content => template('opencontrailid/recaptcha.php.erb'),
        owner   => 'root',
        group   => 'www-data',
        mode    => '0640',
        require => [
          File['/etc/opencontrailid'],
        ]
  }

  $docroot_dirs = [ '/srv/opencontrailid' ]

  file { $docroot_dirs:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  include apache
  include apache::ssl
  include apache::php
  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => '/srv/opencontrailid/w/public',
    priority => '50',
    template => 'opencontrailid/vhost.erb',
    ssl      => true,
    require  => File[$docroot_dirs],
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

  deploy { 'deploytool':
  }

  file { '/opt/deploy/conf.d/opencontrailid.conf':
    content => template('opencontrailid/opencontrailid.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Deploy['deploytool'],
  }

  exec { 'deploy-site':
    path      => '/usr/bin:/bin:/usr/local/bin',
    command   => '/opt/deploy/deploy.sh init opencontrailid',
    onlyif    => '/opt/deploy/deploy.sh status opencontrailid | grep N/A',
    logoutput => on_failure,
    require   => [
      File['/opt/deploy/conf.d/opencontrailid.conf'],
      Apache::Vhost[$vhost_name],
      File['/etc/opencontrailid/recaptcha.php'],
      File['/etc/opencontrailid/database.php'],
      File['/etc/opencontrailid/log.php'],
      File['/etc/opencontrailid/environment.php'],
      Package[$php5_packages] ],
  }

}
