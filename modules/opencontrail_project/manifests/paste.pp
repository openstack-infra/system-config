# == Class: opencontrail_project::paste
#
class opencontrail_project::paste (
  $sysadmins = []
) {
  class { 'opencontrail_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include lodgeit
  lodgeit::site { 'opencontrail':
    port  => '5000',
    image => 'header-bg2.png',
  }

  lodgeit::site { 'drizzle':
    port => '5001',
  }
}
