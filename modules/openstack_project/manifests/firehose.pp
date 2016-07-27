# Copyright 2016 Hewlett-Packard Development Company, L.P.
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
# firehose glue class.
#
class openstack_project::firehose (
  $gerrit_username = 'germqtt',
  $gerrit_public_key,
  $gerrit_private_key,
  $gerrit_ssh_host_key,
  $mqtt_hostname = 'firehose01.openstack.org',
  $mqtt_password,
  $mqtt_username = 'infra',
  $ssl_cert_file = '',
  $ssl_cert_file_contents = '',
  $ssl_key_file = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file = '',
  $ssl_chain_file_contents = '',
) {

  file { '/etc/ssl/certs':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/ssl/private':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # To use the standard ssl-certs package snakeoil certificate, leave both
  # $ssl_cert_file and $ssl_cert_file_contents empty. To use an existing
  # certificate, specify its path for $ssl_cert_file and leave
  # $ssl_cert_file_contents empty. To manage the certificate with puppet,
  # provide $ssl_cert_file_contents and optionally specify the path to use for
  # it in $ssl_cert_file.
  if ($ssl_cert_file == '') and ($ssl_cert_file_contents == '') {
    $cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
  } else {
    if $ssl_cert_file == '' {
      $cert_file = "/etc/ssl/certs/${::fqdn}.pem"
    } else {
      $cert_file = $ssl_cert_file
    }
    if $ssl_cert_file_contents != '' {
      file { $cert_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $ssl_cert_file_contents,
        require => File['/etc/ssl/certs'],
      }
    }
  }

  # To use the standard ssl-certs package snakeoil key, leave both
  # $ssl_key_file and $ssl_key_file_contents empty. To use an existing key,
  # specify its path for $ssl_key_file and leave $ssl_key_file_contents empty.
  # To manage the key with puppet, provide $ssl_key_file_contents and
  # optionally specify the path to use for it in $ssl_key_file.
  if ($ssl_key_file == '') and ($ssl_key_file_contents == '') {
    $key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
  } else {
    if $ssl_key_file == '' {
      $key_file = "/etc/ssl/private/${::fqdn}.key"
    } else {
      $key_file = $ssl_key_file
    }
    if $ssl_key_file_contents != '' {
      file { $key_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => $ssl_key_file_contents,
        require => File['/etc/ssl/private'],
      }
    }
  }

  # To avoid using an intermediate certificate chain, leave both
  # $ssl_chain_file and $ssl_chain_file_contents empty. To use an existing
  # chain, specify its path for $ssl_chain_file and leave
  # $ssl_chain_file_contents empty. To manage the chain with puppet, provide
  # $ssl_chain_file_contents and optionally specify the path to use for it in
  # $ssl_chain_file.
  if ($ssl_chain_file == '') and ($ssl_chain_file_contents == '') {
    $chain_file = ''
  } else {
    if $ssl_chain_file == '' {
      $chain_file = "/etc/ssl/certs/${::fqdn}_intermediate.pem"
    } else {
      $chain_file = $ssl_chain_file
    }
    if $ssl_chain_file_contents != '' {
      file { $chain_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $ssl_chain_file_contents,
        require => File['/etc/ssl/certs'],
        before  => File[$cert_file],
      }
    }
  }

  include mosquitto
  class {'mosquitto::server':
    log_file => '/var/log/mosquitto.log',
    infra_service_username => $mqtt_username,
    infra_service_password => $mqtt_password,
    enable_tls             => true,
    cert_file              => $cert_file
    key_file               => $key_file
    ca_file                => $something
  }

  include germqtt
  class {'germqtt::server':
    gerrit_username    => $gerrit_username,
    gerrit_public_key  => $gerrit_public_key,
    gerrit_private_key => $gerrit_private_key,
    gerrit_host_key    => $gerrit_host_key,
    mqtt_username      => $mqtt_username,
    mqtt_password      => $mqtt_password,
  }
}
