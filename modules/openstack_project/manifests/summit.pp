class openstack_project::summit (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
  }

  realize (
    User::Virtual::Localuser['ttx'],
  )
}

# vim:sw=2:ts=2:expandtab:textwidth=79
