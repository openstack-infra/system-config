# == Class: openstack_project::docker
#
class openstack_project::docker-registry () {
  package { 'docker-registry':
    ensure => present,
  }

  file { '/etc/docker/registry/config.yml':
    ensure => present,
    source  => 'puppet:///modules/openstack_project/docker-registry/config.yml',
    require => Package['docker-registry'],
  }
  file { '/etc/docker/registry/users':
    ensure => present,
    source  => 'puppet:///modules/openstack_project/docker-registry/users',
    require => Package['docker-registry'],
  }
}
