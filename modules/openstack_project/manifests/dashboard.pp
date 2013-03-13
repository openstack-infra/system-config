class openstack_project::dashboard(
    $password = '',
    $mysql_password = '',
    $sysadmins = []
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 3000],
    sysadmins                 => $sysadmins
  }

  class { '::dashboard':
    dashboard_ensure    => 'present',
    dashboard_user      => 'www-data',
    dashboard_group     => 'www-data',
    dashboard_password  => $password,
    dashboard_db        => 'dashboard_prod',
    dashboard_charset   => 'utf8',
    dashboard_site      => $::fqdn,
    dashboard_port      => '3000',
    mysql_root_pw       => $mysql_password,
    passenger           => true,
  }

  mysql::server::config[1] { '/etc/mysql/conf.d/50_innodb_file_per_table':
    ensure  => present,
    source  => 'puppet://modules/openstack_project/dashboard/mysql_innodb_file_per_table',
    require => Class['mysql::server'],
    notify  => Class['mysql::server'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
