class etherpad_lite::site (
  $dbType = 'mysql',
  $database_user = 'eplite',
  $database_name = 'etherpad-lite',
  $database_password,
) {

  include etherpad_lite

  if $dbType == 'mysql' {
    service { 'etherpad-lite':
      enable    => true,
      ensure    => running,
      subscribe => File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"],
      require   => Class['etherpad_lite::mysql'],
    }
  }
  else {
    service { 'etherpad-lite':
      enable    => true,
      ensure    => running,
      subscribe => File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"],
    }
  }

  file { "${etherpad_lite::base_install_dir}/etherpad-lite/settings.json":
    ensure  => 'present',
    content => template('etherpad_lite/etherpad-lite_settings.json.erb'),
    replace => true,
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => 0600,
    require => Class['etherpad_lite']
  }

  file { "${etherpad_lite::base_install_dir}/etherpad-lite/src/static/custom/pad.js":
    ensure  => 'present',
    source  => 'puppet:///modules/etherpad_lite/pad.js',
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => 0644,
    require => Class['etherpad_lite']
  }

  file { "${etherpad_lite::base_install_dir}/etherpad-lite/src/static/robots.txt":
    ensure  => present,
    source  => 'puppet:///modules/etherpad_lite/robots.txt',
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => '0644',
    require => Class['etherpad_lite'],
  }

  include logrotate
  logrotate::file { 'epliteerror':
    log     => "${etherpad_lite::base_log_dir}/${etherpad_lite::ep_user}/error.log",
    options => ['compress', 'copytruncate', 'missingok', 'rotate 7', 'daily', 'notifempty'],
    require => Service['etherpad-lite']
  }

  logrotate::file { 'epliteaccess':
    log     => "${etherpad_lite::base_log_dir}/${etherpad_lite::ep_user}/access.log",
    options => ['compress', 'copytruncate', 'missingok', 'rotate 7', 'daily', 'notifempty'],
    require => Service['etherpad-lite']
  }

}
