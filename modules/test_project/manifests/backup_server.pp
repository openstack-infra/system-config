# == Class: openstack_project::backup_server
#
class openstack_project::backup_server {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => [],
  }
  package { 'bup':
    ensure => present,
  }
}
