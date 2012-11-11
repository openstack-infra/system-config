# Class: bup
#
class bup {
  package { 'bup':
    ensure => present,
  }

  file { '/etc/bup-excludes':
    ensure  => present,
    content => 'puppet:///modules/bup/etc/bup-exculdes',
  }
}
