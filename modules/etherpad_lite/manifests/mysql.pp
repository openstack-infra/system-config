class etherpad_lite::mysql (
  $dbType = 'mysql',
  $database_user = 'eplite',
  $database_name = 'etherpad-lite',
  $database_password
) {

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

  file { "${etherpad_lite::base_install_dir}/etherpad-lite/create_database.sh":
    ensure  => 'present',
    content => template('etherpad_lite/create_database.sh.erb'),
    replace => true,
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => 0755,
    require => Class['etherpad_lite']
  }

  file { "${etherpad_lite::base_install_dir}/etherpad-lite/create_user.sh":
    ensure  => 'present',
    content => template('etherpad_lite/create_user.sh.erb'),
    replace => true,
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => 0755,
    require => Class['etherpad_lite']
  }

  exec { "create-etherpad-lite-db":
    unless  => "mysql --defaults-file=/etc/mysql/debian.cnf ${database_name}",
    path    => ['/bin', '/usr/bin'],
    command => "${etherpad_lite::base_install_dir}/etherpad-lite/create_database.sh",
    require => [Service['mysql'],
                File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"],
                File["${etherpad_lite::base_install_dir}/etherpad-lite/create_database.sh"]]
  } ->

  exec { "grant-etherpad-lite-db":
    unless  => "mysql -u${database_user} -p${database_password} ${database_name}",
    path    => ['/bin', '/usr/bin'],
    command => "${etherpad_lite::base_install_dir}/etherpad-lite/create_user.sh",
    require => [Service['mysql'],
                File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"],
                File["${etherpad_lite::base_install_dir}/etherpad-lite/create_user.sh"]]
  }

}
