class openstack_project::dashboard(
    $password = '',
    $mysql_password = '',
    $sysadmins = []
) {
  require mysql

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

  mysql::server::config { '50_innodb_file_per_table':
    settings => '[mysqld]\ninnodb_file_per_table\n',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
