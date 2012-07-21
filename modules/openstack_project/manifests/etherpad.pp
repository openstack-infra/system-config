class openstack_project::etherpad {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443]
  }

  include etherpad_lite
  include etherpad_lite::nginx
  class { 'etherpad_lite::site':
    database_password => hiera('etherpad_db_password'),
  }
  class { 'etherpad_lite::mysql':
    database_password => hiera('etherpad_db_password'),
  }
  include etherpad_lite::backup
}
