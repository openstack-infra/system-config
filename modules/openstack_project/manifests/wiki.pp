# == Class: openstack_project::wiki
#
class openstack_project::wiki (
  $admin_users = [
    'rlane',
  ],
  $use_bup = true,
  $bup_backup_user = 'bup-wiki',
  $bup_backup_server = 'ci-backup-rs-ord.openstack.org',
  $elasticsearch_es_template_config = {
    'bootstrap.mlockall'               => true,
    'discovery.zen.ping.unicast.hosts' => ['localhost'],
  },
  $elasticsearch_version = '1.3.2',
  $elasticsearch_heap_size = '1g',
  $mediawiki_role = 'all',
  $mediawiki_location = '/srv/mediawiki/w',
  $mediawiki_images_location = '/srv/mediawiki/images',
  $memcached_max_memory = 2048,
  $memcached_listen_ip = '127.0.0.1',
  $memcached_tcp_port = 11000,
  $memcached_udp_port = 11000,
  $mysql_root_password = '',
  $mysql_server_default_engin = 'InnoDB',
  $mysql_server_bind_address = '127.0.0.1',
  $sysadmins = [],
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = ''
) {

  package { ['openssl', 'ssl-cert']:
    ensure => present;
  }

  include subversion

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  realize (
    User::Virtual::Localuser[$admin_users],
  )

  class { 'mediawiki':
    role                      => $mediawiki_role,
    mediawiki_location        => $mediawiki_location,
    mediawiki_images_location => $mediawiki_images_location,
    site_hostname             => $::fqdn,
    ssl_cert_file             => "/etc/ssl/certs/${::fqdn}.pem",
    ssl_key_file              => "/etc/ssl/private/${::fqdn}.key",
    ssl_chain_file            => '/etc/ssl/certs/intermediate.pem',
    ssl_cert_file_contents    => $ssl_cert_file_contents,
    ssl_key_file_contents     => $ssl_key_file_contents,
    ssl_chain_file_contents   => $ssl_chain_file_contents,
  }
  class { 'memcached':
    max_memory => $memcached_max_memory,
    listen_ip  => $memcached_listen_ip,
    tcp_port   => $memcached_tcp_port,
    udp_port   => $memcached_udp_port,
  }
  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => $mysql_server_default_engin,
      'bind_address'   => $mysql_server_bind_address,
    }
  }
  include mysql::server::account_security

  mysql_backup::backup { 'wiki':
    require => Class['mysql::server'],
  }

  if $use_bup {
    include bup
    bup::site { 'rs-ord':
      backup_user     => $bup_backup_user,
      backup_server   => $bup_backup_server,
    }
  }

  class { '::elasticsearch':
    es_template_config => $elasticsearch_es_template_config,
    version            => $elasticsearch_version,
    heap_size          => $elasticsearch_heap_size,
  }

}
