class openstack_project::etherpad(
  $etherpad_crt,
  $etherpad_key,
  $database_password) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443]
  }

  include etherpad_lite
  class { 'etherpad_lite::apache':
    etherpad_crt => $etherpad_crt,
    etherpad_key => $etherpad_key,
  }
  class { 'etherpad_lite::site':
    database_password => $database_password,
  }
  class { 'etherpad_lite::mysql':
    database_password => $database_password,
  }
  include etherpad_lite::backup
}
