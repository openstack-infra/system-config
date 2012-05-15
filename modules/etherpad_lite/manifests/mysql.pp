class etherpad_lite::mysql {

  include etherpad_lite

  package { 'mysql-server':
    ensure => present
  }

  package { 'mysql-client':
    ensure => present
  }

  service { "mysql":
    enable     => true,
    ensure     => running,
    hasrestart => true,
    require    => [Package['mysql-server'],
                   Package['mysql-client']]
  }

  exec { "create-etherpad-lite-db":
    unless  => 'mysql --defaults-file=/etc/mysql/debian.cnf etherpad-lite',
    path    => ['/bin', '/usr/bin'],
    command => "mysql --defaults-file=/etc/mysql/debian.cnf -e \"create database \`etherpad-lite\` CHARACTER SET utf8 COLLATE utf8_bin;\"",
    require => [Service['mysql'],
                File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"]]
  } ->

  exec { "grant-etherpad-lite-db":
    unless  => "mysql -ueplite -p'`grep password ${etherpad_lite::base_install_dir}/etherpad-lite/settings.json | cut -d: -f2 | sed -e 's/.*\"\(.*\)\".*/\1/'`' etherpad-lite",
    path    => ['/bin', '/usr/bin'],
    command => "mysql --defaults-file=/etc/mysql/debian.cnf -e \"grant all on \`etherpad-lite\`.* to 'eplite'@'localhost' identified by '`grep password ${etherpad_lite::base_install_dir}/etherpad-lite/settings.json | cut -d: -f2 | sed -e 's/.*\"\(.*\)\".*/\1/'`';\" mysql",
    require => [Service['mysql'],
                File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"]]
  }

}
