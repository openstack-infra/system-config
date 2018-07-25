include ::apt

package { 'ssl-cert':
  ensure => present,
}

$sysadmins = []
$gerrit_username = 'germqtt'
$gerrit_public_key = ''
$gerrit_private_key = ''
$gerrit_ssh_host_key = ''
$imap_username = 'firehose'
$imap_hostname = 'localhost'
$imap_password = 'firehose'
$mqtt_hostname = 'localhost'
$mqtt_password = 'firehose'
$mqtt_username = 'infra'
$statsd_host = 'graphite.openstack.org'
$ca_file = undef
$cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
$key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'

include mosquitto
class {'mosquitto::server':
  infra_service_username => $mqtt_username,
  infra_service_password => $mqtt_password,
  enable_tls             => true,
  enable_tls_websocket   => true,
  ca_file                => $ca_file,
  cert_file              => $cert_file,
  key_file               => $key_file,
  websocket_tls_port     => 443,
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

package {'sasl2-bin':
  ensure => latest,
}

package {'cyrus-admin':
  ensure => latest,
}

service {'cyrus-imapd':
  ensure => running,
}

class {'::exim':
  sysadmins => $sysadmins,
  local_domains => "@:firehose.openstack.org",
  default_localuser_router => false,
  routers  => [
    {'cyrus' => {
      'driver'                     => 'accept',
      'domains'                    => '+local_domains',
      'local_part_suffix'          => '+*',
      'local_part_suffix_optional' => true,
      'transport'                  => 'cyrus',
    }},
    {'localuser' => {
      'driver'               => 'accept',
      'check_local_user'     => true,
      'transport'            => 'local_delivery',
      'cannot_route_message' => 'Unknown user',
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
  imap_use_ssl  => false,
  imap_delete_old => true,
}

include mqtt_statsd
class {'mqtt_statsd::server':
  mqtt_hostname   => $mqtt_hostname,
  statsd_hostname => $statsd_host,
}
