# Class seafile
#
class seafile (
) {
  include apache
  # get gini/archive module from puppet forge
  include archive

  file { '/srv/seafile' :
    ensure  => directory,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0755',
    require => User['seafile'],
  }

  group { 'seafile' :
    ensure => present,
  }

  user { 'seafile' :
    ensure     => present,
    home       => '/srv/seafile',
    shell      => '/bin/bash',
    gid        => 'seafile',
    managehome => true,
    require    => Group['seafile'],
  }

}
