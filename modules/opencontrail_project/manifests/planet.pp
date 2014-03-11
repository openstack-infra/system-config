# == Class: opencontrail_project::planet
#
class opencontrail_project::planet (
  $sysadmins = []
) {
  class { 'opencontrail_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include ::planet

  planet::site { 'opencontrail':
    git_url => 'git://git.opencontrail.org/opencontrail/opencontrail-planet',
  }
}
