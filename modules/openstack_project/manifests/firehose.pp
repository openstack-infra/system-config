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
  $sysadmins = [],
  $gerrit_username = 'germqtt',
  $gerrit_public_key,
  $gerrit_private_key,
  $gerrit_ssh_host_key,
  $imap_username,
  $imap_hostname,
  $imap_password,
  $mqtt_hostname = 'firehose01.openstack.org',
  $mqtt_password,
  $mqtt_username = 'infra',
  $ca_file,
  $cert_file,
  $key_file,
) {
  include mosquitto
  class {'mosquitto::server':
    infra_service_username => $mqtt_username,
    infra_service_password => $mqtt_password,
    enable_tls             => true,
    ca_file                => $ca_file,
    cert_file              => $cert_file,
    key_file               => $key_file,
  }

  include germqtt
  class {'germqtt::server':
    gerrit_username     => $gerrit_username,
    gerrit_public_key   => $gerrit_public_key,
    gerrit_private_key  => $gerrit_private_key,
    gerrit_ssh_host_key => $gerrit_ssh_host_key,
    mqtt_username       => $mqtt_username,
    mqtt_password       => $mqtt_password,
  }

  package {'cyrus-imapd':
    ensure => latest,
  }

  class {'::exim':
    syasmins => $sysadmins,
    routers  => [
      {'cyrus' => {
        'driver'                     => 'accept',
        'domains'                    => '+local_domains',
        'local_part_suffix'          => '+*',
        'local_part_suffix_optional' => true,
        'transport'                  => 'cyrus',
      }}
    ],
    transports => [
      {'cyrus' => {
        'driver'    => 'lmtp',
        'socket'    => '/var/run/cyrus/socket/lmtp',
        'user'      => 'cyrus',
        'batch_max' => '35',
      }}
    ],
    require  => Package['cyrus-imapd'],
  }

  include lpmqtt
  class {'lpmqtt::server':
    mqtt_username => $mqtt_username,
    mqtt_password => $mqtt_password,
    imap_hostname => $imap_hostname,
    imap_username => $imap_username,
    imap_password => $imap_password,
    imap_use_ssl  => true,
  }
}
