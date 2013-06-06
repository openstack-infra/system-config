# Class: bup
#
class bup {
  package { 'bup':
    ensure => present,
  }

  file { '/etc/bup-excludes':
    ensure => present,
    source => 'puppet:///modules/bup/etc/bup-excludes',
  }

  file { '/usr/local/bup':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    source  => 'puppet:///modules/bup/scripts',
  }

}
