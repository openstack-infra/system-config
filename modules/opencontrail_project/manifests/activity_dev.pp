# Server for activity board - staging
class openstack_project::activity_dev (
  $site_admin_password = '',
  $site_mysql_password = '',
  $site_mysql_host = '',
  $sysadmins = [],
) {


  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins,
  }

  realize (
    User::Virtual::LocalUser['smaffulli'],
  )

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
    mode    => '0775',
    require => [
      File['/srv/static'],
      Package['apache2'],
    ]
  }

  file { '/srv/static':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

}
