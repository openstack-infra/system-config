# Class seafile
#
class seafile (
) {
  include apache

  # download the tarball and unpack it

  # create the 5 directories and 5 files the config script generates
  # ccnet/ccnet.conf
  file { '/srv/seafile/ccnet/ccnet.conf' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/ccnet/ccnet.conf'),
  }
  # ccnet/mykey.peer
  file { '/srv/seafile/ccnet/mykey.peer' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/ccnet/mykey.peer'),
  }
  # ccnet/seafile.ini
  file { '/srv/seafile/ccnet/seafile.ini' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/ccnet/seafile.ini'),
  }
  # seafile-data/seafile.conf
  file { '/srv/seafile/seafile-data/seafile.conf' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/seafile-data/seafile.conf'),
  }
  # seahub-data/avatars/groups/
  # seahub_settings.py
  file { '/srv/seafile/seahub_settings.py' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/seahub_settings.py'),
  }

  # make it run
}
