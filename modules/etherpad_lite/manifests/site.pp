# == Class: etherpad_lite::site
#
class etherpad_lite::site (
  $database_password,
  $etherpad_title,
  $sessionKey    = '',
  $dbType        = 'mysql',
  $database_user = 'eplite',
  $database_name = 'etherpad-lite',
  $database_host = 'localhost'
) {

  include etherpad_lite

  $base = $etherpad_lite::base_install_dir

  service { 'etherpad-lite':
    ensure    => running,
    enable    => true,
    subscribe => File["${base}/etherpad-lite/settings.json"],
  }

  file { "${base}/etherpad-lite/settings.json":
    ensure  => present,
    content => template('etherpad_lite/etherpad-lite_settings.json.erb'),
    replace => true,
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => '0600',
    require => Class['etherpad_lite'],
  }

  file { "${base}/etherpad-lite/src/static/custom/pad.js":
    ensure  => present,
    source  => 'puppet:///modules/etherpad_lite/pad.js',
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => '0644',
    require => Class['etherpad_lite'],
  }

  file { "${base}/etherpad-lite/src/static/robots.txt":
    ensure  => present,
    source  => 'puppet:///modules/etherpad_lite/robots.txt',
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => '0644',
    require => Class['etherpad_lite'],
  }

  include logrotate
  logrotate::file { 'epliteerror':
    log     => "${base}/${etherpad_lite::ep_user}/error.log",
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service['etherpad-lite'],
  }

  logrotate::file { 'epliteaccess':
    log     => "${base}/${etherpad_lite::ep_user}/access.log",
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service['etherpad-lite'],
  }
}
