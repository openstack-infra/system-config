class openstack_project::community (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 8099, 8080],
    sysadmins                 => $sysadmins
  }

  realize (
    User::Virtual::Localuser['smaffulli'],
  )
}

# vim:sw=2:ts=2:expandtab:textwidth=79
