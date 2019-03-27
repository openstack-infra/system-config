# == Define: openstack_project::mirror_update
#
define openstack_project::reprepro (
  $confdir,
  $basedir,
  $distributions,
  $logdir = '/var/log/reprepro',
  $updates_file = undef,
  $options_template = 'openstack_project/reprepro/options.erb',
  $releases = [],
  $skip_backports_for = [],
) {
  file { "$confdir":
    ensure => directory,
  }

  if $updates_file != undef {
    file { "${confdir}/updates":
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => $updates_file,
    }
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
