class openstack_project::etherpad {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443]
  }

  include etherpad_lite
  class { 'etherpad_lite::nginx':
    etherpad_crt => hiera('etherpad_crt'),
    etherpad_key => hiera('etherpad_key')
  }
  class { 'etherpad_lite::site':
    database_password => hiera('etherpad_db_password'),
  }
  class { 'etherpad_lite::mysql':
    database_password => hiera('etherpad_db_password'),
  }
  include etherpad_lite::backup
}
