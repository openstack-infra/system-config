# == Class: openstack_project::reprepro_mirror
#
class openstack_project::reprepro_mirror {
  package { 'reprepro':
    ensure => present,
  }

  file { '/var/log/reprepro':
    ensure => directory,
  }

  file { '/var/run/reprepro':
    ensure => directory,
  }

  file { '/etc/reprepro':
    ensure => directory,
  }

  cron { 'reprepro':
    ensure => absent,
  }
}
