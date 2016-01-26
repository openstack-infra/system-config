# == Class: openstack_project::mirror_update
#
class openstack_project::reprepro (
  $outdir = '/afs/.openstack.org/mirror/apt',
  $logdir = '/var/log/reprepro',
  $updates_file = 'puppet:///modules/openstack_project/reprepro/updates',
  $options_template = 'openstack_project/reprepro/options.erb',
  $distributions_template = 'openstack_project/reprepro/distributions.erb',
) {

  package { 'reprepro':
    ensure => present,
  }

  file { '/etc/reprepro':
    ensure => directory,
  }

  file { $logdir:
    ensure => directory,
  }

  file { '/etc/reprepro':
    ensure => directory,
  }

  file { '/var/run/reprepro':
    ensure => directory,
  }

  file { '/etc/reprepro/updates':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => $updates_file,
  }

  file { '/etc/reprepro/options':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template($options_template),
  }

  file { '/etc/reprepro/distributions':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template($distributions_template),
  }
}
