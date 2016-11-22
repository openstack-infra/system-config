# == Class: openstack_project::docker
#
class openstack_project::docker () {
  package { 'docker':
    ensure => present,
  }

  file { '/etc/docker-config-file':
    ensure => present,
    source  => 'puppet:///modules/openstack_project/docker/config',
    require => Package['docker'],
  }
}
