class openstack_project::etherpad (
  $etherpad_crt,
  $etherpad_key,
  $database_password,
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins
  }

  include etherpad_lite
  include etherpad_lite::backup

  class { 'etherpad_lite::apache':
    etherpad_crt  => $etherpad_crt,
    etherpad_key  => $etherpad_key,
  }

  class { 'etherpad_lite::site':
    database_password => $database_password,
  }

  class { 'etherpad_lite::mysql':
    database_password => $database_password,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
