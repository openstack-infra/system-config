# == Class: openstack_project::mirror_update
#
class openstack_project::reprepro (
  $confdir,
  $basedir,
  $distributions,
  $logdir = '/var/log/reprepro',
  $updates_file = 'puppet:///modules/openstack_project/reprepro/updates',
  $options_template = 'openstack_project/reprepro/options.erb',
  $releases = [],
) {

  package { 'reprepro':
    ensure => present,
  }

  file { $logdir:
    ensure => directory,
  }

  file { '/etc/reprepro':
    ensure => directory,
  }

  file { "$confdir":
    ensure => directory,
  }

  file { '/var/run/reprepro':
    ensure => directory,
  }

  file { "${confdir}/updates":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => $updates_file,
  }

  file { "${confdir}/options":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template($options_template),
  }

  file { "${confdir}/distributions":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template($distributions),
  }
}
