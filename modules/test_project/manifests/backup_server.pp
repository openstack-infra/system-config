# == Class: test_project::backup_server
#
class test_project::backup_server {
  class { 'test_project::template':
    iptables_public_tcp_ports => [],
  }
  package { 'bup':
    ensure => present,
  }
}
