# == Class: ssl_cert_check
#
class ssl_cert_check(
  $domainlist_file = '',
  $email = '',
  $days = ''
) {
  package { 'ssl-cert-check':
    ensure => present,
  }

  file {'/var/lib/certcheck':
    ensure  => directory,
    owner   => 'certcheck',
    group   => 'certcheck',
    mode    => '0755',
    require => User['certcheck'],
  }

  group { 'certcheck':
    ensure => present,
  }

  user { 'certcheck':
    ensure     => present,
    home       => '/var/lib/certcheck',
    shell      => '/bin/bash',
    gid        => 'certcheck',
    managehome => true,
    require    => Group['certcheck'],
  }

  cron { 'check ssl certificates':
    user    => 'certcheck',
    command => "ssl-cert-check -a -q -f ${domainlist_file} -x ${days} -e ${email}",
    hour    => '12',
    minute  => '04',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
