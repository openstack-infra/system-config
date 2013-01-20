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
}
