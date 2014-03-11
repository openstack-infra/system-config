# == Class: opencontrail_project::backup_server
#
class opencontrail_project::backup_server {
  class { 'opencontrail_project::template':
    iptables_public_tcp_ports => [],
  }
}
