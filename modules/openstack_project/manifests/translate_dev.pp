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
# == Class: openstack_project::translate_dev
#
class openstack_project::translate_dev(
  $mysql_host = 'localhost',
  $mysql_port = '3306',
  $mysql_user = 'zanata',
  $mysql_password,
  $admin_users = '',
  $sysadmins = [],
  $zanata_server_user = '',
  $zanata_server_api_key = '',
  $project_config_repo = '',
  $openid_url = '',
  $vhost_name = $::fqdn,
  $ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $listeners = [],
  $from_address,
  ) {

  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80, 443],
  }

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
    zanata_url                  => 'https://sourceforge.net/projects/zanata/files/webapp/zanata-war-3.9.6.war',
    zanata_checksum             => '67a360616eaf442b089a39921ff22149d2f0fdb5',
    require                     => [
                                   Class['openstack_project::server']
                                   ],
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
