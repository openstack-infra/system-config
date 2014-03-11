# User group management server
class opencontrail_project::groups (
  $sysadmins = []
) {
  class { 'opencontrail_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }
}
