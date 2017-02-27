# Copyright 2015 Hewlett-Packard Development Company, L.P.
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
# == Class: openstack_project::translate
#
class openstack_project::translate(
  $mysql_host = 'localhost',
  $mysql_port = '3306',
  $mysql_user = 'zanata',
  $mysql_password,
  $admin_users = '',
  $zanata_server_user = '',
  $zanata_server_api_key = '',
  $zanata_wildfly_version = '9.0.1',
  $zanata_wildfly_install_url = 'https://repo1.maven.org/maven2/org/wildfly/wildfly-dist/9.0.1.Final/wildfly-dist-9.0.1.Final.tar.gz',
  $zanata_url = '',
  $zanata_checksum = '',
  $project_config_repo = '',
  $openid_url = '',
  $vhost_name = $::fqdn,
  $ssl_cert_file = "/etc/ssl/certs/${::fqdn}.pem",
  $ssl_key_file = "/etc/ssl/private/${::fqdn}.key",
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $listeners = [],
  $from_address,
  ) {

  class { 'project_config':
    url  => $project_config_repo,
  }

  class { '::zanata':
    mysql_host                  => $mysql_host,
    mysql_port                  => $mysql_port,
    zanata_db_username          => $mysql_user,
    zanata_db_password          => $mysql_password,
    zanata_openid_provider_url  => $openid_url,
    zanata_listeners            => $listeners,
    zanata_admin_users          => $admin_users,
    zanata_default_from_address => $from_address,
    zanata_wildfly_version      => $zanata_wildfly_version,
    zanata_wildfly_install_url  => $zanata_wildfly_install_url,
    zanata_url                  => $zanata_url,
    zanata_checksum             => $zanata_checksum,
  }

  class { '::zanata::apache':
    vhost_name              => $vhost_name,
    ssl_cert_file           => $ssl_cert_file,
    ssl_key_file            => $ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    require                 => Class['::zanata']
  }

  include logrotate
  logrotate::file { 'console.log':
    log     => '/var/log/wildfly/console.log',
    options => [
                'daily',
                'rotate 30',
                'missingok',
                'dateext',
                'copytruncate',
                'compress',
                'delaycompress',
                'notifempty',
                'maxage 30',
                ],
    require => Service['wildfly'],
  }

  file { '/home/wildfly/projects.yaml':
    ensure  => present,
    owner   => 'wildfly',
    group   => 'wildfly',
    mode    => '0444',
    source  => $::project_config::jeepyb_project_file,
    replace => true,
    require => User['wildfly'],
  }

  include jeepyb
  exec { 'register-zanata-projects':
    command     => '/usr/local/bin/register-zanata-projects -v -l /var/log/register-zanata-projects.log',
    timeout     => 900, # 15 minutes
    subscribe   => File['/home/wildfly/projects.yaml'],
    refreshonly => true,
    logoutput   => true,
    environment => [
        "PROJECTS_YAML=/home/wildfly/projects.yaml",
        "ZANATA_URL=https://${vhost_name}/",
        "ZANATA_USER=${zanata_server_user}",
        "ZANATA_KEY=${zanata_server_api_key}",
    ],
    require     => [
        File['/home/wildfly/projects.yaml'],
        Class['jeepyb'],
      ],
  }

  logrotate::file { 'register-zanata-projects.log':
    log     => '/var/log/register-zanata-projects.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
      'copytruncate',
    ],
    require => Exec['register-zanata-projects'],
  }
}
