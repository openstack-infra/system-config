class opencontrail_project::summit (
  $sysadmins = []
) {
  class { 'opencontrail_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins
  }

  realize (
    User::Virtual::Localuser['ttx'],
  )
}

# vim:sw=2:ts=2:expandtab:textwidth=79
