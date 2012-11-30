# Class: pip
#
class pip {
  package { 'python-all-dev':
    ensure => present,
  }

  package { 'python-pip':
    ensure  => present,
    require => Package['python-all-dev'],
  }
}
