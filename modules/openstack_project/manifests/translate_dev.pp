# Copyright 2013 Hewlett-Packard Development Company, L.P.
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
  $mysql_user = 'zanata',
  $mysql_port = '3306',
  $mysql_password,
  $sysadmins = [],
  $openid_url = '',
  $vhost_name = $::fqdn,
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  ) {

  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80, 443],
  }

  class { '::zanata::mysql':
    mysql_user  => $mysql_user,
    mysql_host  => $mysql_host,
    mysql_port  => $mysql_port,
    db_password => $mysql_password,
  }

  class { '::zanata':
    zanata_db_username         => $mysql_user,
    zanata_db_password         => $mysql_password,
    zanata_openid_provider_url => $openid_url,
    require                    => [
                                   Class['openstack_project::server']
                                   ],
  }

  if $ssl_cert_file == '' {
    $prv_ssl_cert_file = "/etc/ssl/certs/${vhost_name}.pem"
  } else {
    $prv_ssl_cert_file = $ssl_cert_file
  }

  if $ssl_key_file == '' {
    $prv_ssl_key_file = "/etc/ssl/private/${vhost_name}.key"
  } else {
    $prv_ssl_key_file = $ssl_key_file
  }

  if $ssl_chain_file_contents != '' and $ssl_chain_file == '' {
    $prv_ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  } else {
    $prv_ssl_chain_file = $prv_ssl_chain_file
  }

  class { '::zanata::apache':
    vhost_name              => $vhost_name,
    ssl_cert_file           => $prv_ssl_cert_file,
    ssl_key_file            => $prv_ssl_key_file,
    ssl_chain_file          => $prv_ssl_chain_file,
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

  include bup
  bup::site { 'rs-ord':
    backup_user   => 'bup-translate-dev',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}
