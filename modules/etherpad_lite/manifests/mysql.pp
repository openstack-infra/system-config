class etherpad_lite::mysql {

  include etherpad_lite::mysql_settings

  package { 'mysql-server':
    ensure => latest
  }

  package { 'mysql-client':
    ensure => latest
  }

  service { "mysql":
    enable     => true,
    ensure     => running,
    hasrestart => true,
    require    => [Package['mysql-server'],
                   Package['mysql-client']]
  }

  exec { "set-mysql-password":
    unless  => "mysqladmin -uroot -p${etherpad_lite::mysql_settings::rootpasswd} status",
    path    => ["/bin", "/usr/bin"],
    command => "mysqladmin -uroot password ${etherpad_lite::mysql_settings::rootpasswd}",
    require => [Service['mysql'],
                Class['mysql_settings']]
  } ->

  exec { "create-${etherpad_lite::mysql_settings::database}-db":
    unless  => "mysql -uroot -p${etherpad_lite::mysql_settings::rootpasswd} ${etherpad_lite::mysql_settings::database}",
    path    => ["/bin", "/usr/bin"],
    command => "mysql -uroot -p${etherpad_lite::mysql_settings::rootpasswd} -e \"create database \`${etherpad_lite::mysql_settings::database}\` CHARACTER SET utf8 COLLATE utf8_bin;\"",
    require => Service['mysql'],
  } ->

  exec { "grant-${etherpad_lite::mysql_settings::database}-db":
    unless  => "mysql -u${etherpad_lite::mysql_settings::ep_user} -p${etherpad_lite::mysql_settings::eppasswd} ${etherpad_lite::mysql_settings::database}",
    path    => ["/bin", "/usr/bin"],
    command => "mysql -uroot -p${etherpad_lite::mysql_settings::rootpasswd} -e \"grant all on \`${etherpad_lite::mysql_settings::database}\`.* to '${etherpad_lite::mysql_settings::ep_user}'@'localhost' identified by '${etherpad_lite::mysql_settings::eppasswd}';\" mysql",
    require => Service['mysql']
  }

}
