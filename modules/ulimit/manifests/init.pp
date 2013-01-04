# == Class: ulimit
#
class ulimit {

  include ulimit::params

  package { $::ulimit::params::pam_packages:
    ensure => present,
  }

  file { '/etc/security/limits.d':
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
  }

}
