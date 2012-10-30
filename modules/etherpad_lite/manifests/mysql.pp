# == Class: etherpad_lite::mysql
#
class etherpad_lite::mysql(
  $database_password,
  $dbType = 'mysql',
  $database_user = 'eplite',
  $database_name = 'etherpad-lite'
) {
  include etherpad_lite

  $base = "${etherpad_lite::base_install_dir}/etherpad-lite"

  package { 'mysql-server':
    ensure => present,
  }

  package { 'mysql-client':
    ensure => present,
  }

  service { 'mysql':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => [
      Package['mysql-server'],
      Package['mysql-client'],
    ],
  }

  file { "${base}/create_database.sh":
    ensure  => present,
    content => template('etherpad_lite/create_database.sh.erb'),
    group   => $etherpad_lite::ep_user,
    mode    => '0755',
    owner   => $etherpad_lite::ep_user,
    replace => true,
    require => Class['etherpad_lite'],
  }

  file { "${base}/create_user.sh":
    ensure  => present,
    content => template('etherpad_lite/create_user.sh.erb'),
    group   => $etherpad_lite::ep_user,
    mode    => '0755',
    owner   => $etherpad_lite::ep_user,
    replace => true,
    require => Class['etherpad_lite'],
  }

  exec { 'create-etherpad-lite-db':
    unless  => "mysql --defaults-file=/etc/mysql/debian.cnf ${database_name}",
    path    => [
      '/bin',
      '/usr/bin',
    ],
    command => "${base}/create_database.sh",
    require => [
      Service['mysql'],
      File["${base}/settings.json"],
      File["${base}/create_database.sh"],
    ],
    before  => Exec['grant-etherpad-lite-db'],
  }

  exec { 'grant-etherpad-lite-db':
    unless  =>
      "mysql -u${database_user} -p${database_password} ${database_name}",
    path    => [
      '/bin',
      '/usr/bin'
    ],
    command => "${base}/create_user.sh",
    require => [
      Service['mysql'],
      File["${base}/settings.json"],
      File["${base}/create_user.sh"],
    ],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
