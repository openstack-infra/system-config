# == Class: gerrit::user
#
class gerrit::user {

  group { 'gerrit2':
    ensure => present,
  }

  user { 'gerrit2':
    ensure     => present,
    comment    => 'Gerrit2 User',
    home       => '/home/gerrit2',
    gid        => 'gerrit2',
    shell      => '/bin/bash',
    membership => 'minimum',
    groups     => ['gerrit2'],
    require    => Group['gerrit2'],
  }

  file { '/home/gerrit2':
    ensure  => directory,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0644',
    require => User['gerrit2'],
  }

}
