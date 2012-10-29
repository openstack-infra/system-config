class openstack_project::eavesdrop (
  $nickpass,
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins
  }
  include meetbot

  meetbot::site { 'openstack':
    nick      => 'openstack',
    nickpass  => $nickpass,
    network   => 'FreeNode',
    server    => 'niven.freenode.net:7000',
    channels  => '#openstack #openstack-dev #openstack-meeting',
    use_ssl   => 'True'
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
