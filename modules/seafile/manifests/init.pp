# Class seafile
#
class seafile (
) {
  include apache

  # download the tarball and unpack it

  # create the 5 directories and 5 files the config script generates
  # ccnet/ccnet.conf
  file { '$root_directory/ccnet/ccnet.conf' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/ccnet/ccnet.conf'),
  }
  # ccnet/mykey.peer
  file { '$root_directory/ccnet/mykey.peer' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/ccnet/mykey.peer'),
  }
  # ccnet/seafile.ini
  file { '$root_directory/ccnet/seafile.ini' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/ccnet/seafile.ini'),
  }
  # seafile-data/seafile.conf
  file { '$root_directory/seafile-data/seafile.conf' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/seafile-data/seafile.conf'),
  }
  # seahub-data/avatars/groups/
  # seahub_settings.py
  file { '$root_directory/seahub_settings.py' :
    ensure  => present,
    owner   => '',
    group   => '',
    mode    => '0000',
    content => template ('seafile/seahub_settings.py'),
  }

  # make it run
}
