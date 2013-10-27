# == Define: seafile
#
define seafile::site(
  $seafile_db_host = '',
  $seafile_db_user = '',
  $seafile_db_password = '',
  $sysadmins = '',
  $seafile_user_name = '',
  $seafile_id = '',
  $seafile_instance_name = '',
  $seafile_url = '',
  $seafile_network_port = '',
  $seafile_client_port = '',
  $seafile_db_engine = '',
  $seafile_ccnet_db = '',
  $seafile_db_port = '',
  $seafile_seafile_db_port = '',
  $seafile_http_port = '',
  $seafile_secrec_key = '',
  $seafile_seahub_db = '',
  $seafile_rsa_key_contents = '',
) {

  # download the tarball and unpack it
  $url = 'http://seafile.googlecode.com'
  archive { 'seafile-server_2.0.1' :
    ensure => present,
    url    => "{$url}/files/seafile-server_2.0.1_x86-64.tar.gz",
    target => '/srv/seafile',
  }

  file { '/srv/seafile/installed' :
    ensure  => directory,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0700',
    require => User['seafile'],
  }

  file { '/srv/seafile/ccnet' :
    ensure  => directory,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0700',
    require => User['seafile'],
  }

  file { '/srv/seafile/seafile-data' :
    ensure  => directory,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0700',
    require => User['seafile'],
  }

  file { '/srv/seafile/seahub-data' :
    ensure  => directory,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0700',
    require => User['seafile'],
  }

  # ccnet/mykey.peer
  if $seafile_rsa_key_contents != '' {
    file { '/srv/seafile/ccnet/mykey.peer' :
      owner   => 'seafile',
      group   => 'seafile',
      mode    => '0600',
      content => $seafile_rsa_key_contents,
      replace => true,
      require => File['/srv/seafile/ccnet/'],
    }
  }

  # ccnet/ccnet.conf
  file { '/srv/seafile/ccnet/ccnet.conf' :
    ensure  => present,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0000',
    content => template ('seafile/ccnet/ccnet.conf'),
    require => User['seafile'],
  }
  # ccnet/seafile.ini
  file { '/srv/seafile/ccnet/seafile.ini' :
    ensure  => present,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0000',
    source  => 'puppet:///modules/seafile/seafile.ini',
    require => User['seafile'],
  }
  # seafile-data/seafile.conf
  file { '/srv/seafile/seafile-data/seafile.conf' :
    ensure  => present,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0000',
    content => template ('seafile/seafile-data/seafile.conf'),
    require => User['seafile'],
  }
  # seahub-data/avatars/groups/
  file { '/srv/seafile/avatars/groups/' :
    ensure  => directory,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0700',
    require => User['seafile'],
  }
  # seahub_settings.py
  file { '/srv/seafile/seahub_settings.py' :
    ensure  => present,
    owner   => 'seafile',
    group   => 'seafile',
    mode    => '0000',
    content => template ('seafile/seahub_settings.py'),
    require => User['seafile'],
  }

  # make it run

  exec { 'seafile.sh start' :
    command => 'seafile.sh start',
    cwd     => '/srv/seafile',
    user    => 'seafile',
  }

  exec { 'seahub.sh start' :
    command => 'seahub.sh start',
    cwd     => '/srv/seafile',
    user    => 'seafile',
  }
}
