# == Class: openstack_project::backup_server
#
class openstack_project::backup_server {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [],
    manage_exim               => false,
  }
  package { 'bup':
    ensure => present,
  }
}
