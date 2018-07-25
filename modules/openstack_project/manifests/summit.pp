class openstack_project::summit (
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
