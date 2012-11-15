class openstack_project::etherpad_dev (
  $database_password = '',
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins
  }

  class { 'etherpad_lite':
    # Use the version running on the prod server.
    eplite_version => '4195e11a41c5992bc555cef71246800bceaf1915',
    # Use the version running on the prod server.
    nodejs_version => 'v0.6.16',
    # Once dev install is working replace the above parameters with
    # the following to test automated upgrade by puppet.
    # eplite_version => '1.1.4',
    # nodejs_version => 'v0.8.14',
  }

  include etherpad_lite::backup

  class { 'etherpad_lite::apache':
    ssl_cert_file  => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file   => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file => '',
  }

  class { 'etherpad_lite::site':
    database_password => $database_password,
  }

  class { 'etherpad_lite::mysql':
    database_password => $database_password,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
