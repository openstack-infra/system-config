# == Class: openstack_project::backup_server
#
class openstack_project::backup_server {
  package { 'bup':
    ensure => present,
  }
}
