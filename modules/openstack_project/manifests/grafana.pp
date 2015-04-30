# == Class: openstack_project::grafana
#
class openstack_project::grafana (
  $db_password,
  $mysql_root_password,
  $db_host = '127.0.0.1',
  $db_name = 'grafana',
  $db_user = 'grafana',
  $sysadmins = [],
  $vhost_name = $::fqdn,
) {
  include apache

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }

  class { 'mysql::server':
    config_hash => {
      'bind_address'   => '127.0.0.1',
      'default_engine' => 'InnoDB',
      'root_password'  => $mysql_root_password,
    }
  }

  mysql::db { $db_name:
    grant    => ['all'],
    host     => $db_host,
    password => $db_password,
    user     => $db_user,
    require  => Class['mysql::server'],
  }

  class { '::grafana':
    cfg => {
      'app_mode' => 'production',
      'server'   => {
        http_addr => '127.0.0.1',
        http_port => 8080,
      },
      'database' => {
        type     => 'mysql',
        host     => "${db_host}:3306",
        name     => $db_name,
        user     => $db_user,
        password => $db_password,
      },
      'users'    => {
        allow_sign_up => false,
      },
      'auth.anonymous' => {
        enabled => true,
      },
    },
    require => Mysql::Db[$db_name],
  }

  apache::vhost { $vhost_name:
    docroot   => 'MEANINGLESS ARGUMENT',
    port      => 80,
    priority  => '50',
    template  => 'openstack_project/grafana.vhost.erb',
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
}
