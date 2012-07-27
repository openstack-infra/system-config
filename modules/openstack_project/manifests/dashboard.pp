class openstack_project::dashboard(
    $password,
    $mysql_password) {

  class { 'openstack_project::template':
     iptables_public_tcp_ports => [80, 443, 3000]
  }

  class {'::dashboard':
     dashboard_ensure          => 'present',
     dashboard_user            => 'www-data',
     dashboard_group           => 'www-data',
     dashboard_password        => $password,
     dashboard_db              => 'dashboard_prod',
     dashboard_charset         => 'utf8',
     dashboard_site            => $fqdn,
     dashboard_port            => '3000',
     mysql_root_pw             => $mysql_password,
     passenger                 => true,
  }
}
