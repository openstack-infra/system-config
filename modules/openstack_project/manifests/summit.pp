class openstack_project::summit (
  $admin_users = [
    'ttx',
  ],
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins
  }

  realize (
    User::Virtual::Localuser[$admin_users],
  )
}

# vim:sw=2:ts=2:expandtab:textwidth=79
