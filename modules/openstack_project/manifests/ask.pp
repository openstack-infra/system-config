#
# Askbot server.  Mostly managed outside of puppet.
#
class openstack_project::ask (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins
  }
}
