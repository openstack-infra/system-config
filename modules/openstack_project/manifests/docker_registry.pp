# == Class: openstack_project::docker_registry
#
class openstack_project::docker_registry(
  $username,
  $password,
) {

  package { 'docker-registry':
    ensure => present,
  }

  file { '/etc/docker/registry/config.yml':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/docker_registry/config.yml',
    require => Package['docker-registry'],
  }

  file { '/etc/docker/registry/users':
    ensure  => present,
    content => template('openstack_project/docker_registry/users.erb'),
    require => Package['docker-registry'],
  }
}
