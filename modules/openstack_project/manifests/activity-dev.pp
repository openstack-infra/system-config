# Server for activity board - staging
class openstack_project::activity (
  $mysql_root_password = '',
  $site_admin_password = '',
  $site_mysql_password = '',
  $sysadmins = [],
) {

# include mysql

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  realize (
    User::Virtual::LocalUser['smaffulli'],
  )

  include openstack_project
  include apache

  a2mod { 'rewrite':
    ensure => present,
  }
  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
  }

  apache::vhost {'activity-dev.openstack.org':
    port         => 80,
    priority     => '50',
    docroot      => '/srv/static/dash',
    require      => File['/srv/static/dash'],
  }

  file { '/srv/static/dash':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    require => User['www-data'],
  }

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }
