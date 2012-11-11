# Class pip
#
class pip {
  $packages = [
    'python-all-dev',
    'python-pip',
  ]
  package { $packages:
    ensure => present,
  }
}
