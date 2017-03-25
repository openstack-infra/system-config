# == Class: openstack_project::backup_server
#
class openstack_project::backup_server {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [],
    manage_exim => false,
    purge_apt_sources => false,
  }
  package { 'bup':
    ensure => present,
  }
}
