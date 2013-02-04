# Class: reviewday
#
class reviewday (
  $vhost_name = "reviewday.${name}.org",
  $serveradmin = "webmaster@${name}.org"
  ) {
  if ! defined(Package['python-launchpadlib']) {
    package { 'python-launchpadlib':
    ensure => present,
  }
  package { [
    'python-cheetah',
  ]:
  ensure => present,
  }

  file { '/srv/static/reviewday':
    ensure => directory,
    owner  => 'reviewday',
    group  => 'reviewday',
    mode   => '0644',
  }

  file { '/var/lib/reviewday/.ssh/':
    ensure => directory,
    owner  => 'reviewday',
    group  => 'reviewday',
    mode   => '0644',
  }

  user { 'reviewday':
    ensure     => present,
    home       => '/var/lib/reviewday',
    shell      => '/bin/bash',
    gid        => 'reviewday',
    managehome => true,
    require    => Group['reviewday'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
