# == Class: dedupe
#
# base for deduping requirements
class dedupe () {
  file { '/usr/local/bin/dedupe.py':
    ensure  => file,
    path    => '/usr/local/bin/dedupe.py',
    source  => 'puppet:///modules/dedupe/dedupe.py',
    mode    => '0755',
  }
  package { 'fdupes':
    ensure  => present,
  }
}
