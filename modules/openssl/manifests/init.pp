# Class: openssl
#
class openssl {
  $packages = [
    'openssl',
    'ssl-cert',
  ]

  package { $packages:
    ensure => present;
  }
}
