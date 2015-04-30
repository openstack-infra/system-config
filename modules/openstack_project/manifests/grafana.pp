# == Class: openstack_project::grafana
#
class openstack_project::grafana (
  $mysql_password,
  $mysql_root_password,
  $admin_password = '',
  $admin_user = 'admin',
  $mysql_host = '127.0.0.1',
  $mysql_name = 'grafana',
  $mysql_user = 'grafana',
  $vhost_name = $::fqdn,
) {
  include apache

  realize (
    User::Virtual::Localuser['pabelanger'],
  )

  class { 'mysql::server':
    config_hash => {
      'bind_address'   => $mysql_host,
      'default_engine' => 'InnoDB',
      'root_password'  => $mysql_root_password,
    }
  }

  mysql::db { $mysql_name:
    grant    => ['all'],
    host     => $mysql_host,
    password => $mysql_password,
    user     => $mysql_user,
    require  => Class['mysql::server'],
  }

  class { '::grafana':
    cfg => {
      # NOTE(pabelanger): app_mode must be the first key!
      'app_mode' => 'production',
      'analytics' => {
        'reporting_enabled' => false,
      },
      'auth.anonymous' => {
        enabled => true,
      },
      'database' => {
        type     => 'mysql',
        host     => "${mysql_host}:3306",
        name     => $mysql_name,
        user     => $mysql_user,
        password => $mysql_password,
      },
      'security' => {
        admin_password => $admin_password,
        admin_user     => $admin_user,
      },
      'server'   => {
        http_addr => '127.0.0.1',
        http_port => 8080,
      },
      'users'    => {
        allow_sign_up => false,
      },
    },
    require => Mysql::Db[$mysql_name],
  }

  apache::vhost { $vhost_name:
    docroot  => 'MEANINGLESS ARGUMENT',
    port     => 80,
    priority => '50',
    template => 'openstack_project/grafana.vhost.erb',
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
