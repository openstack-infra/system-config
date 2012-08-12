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

  logrotate::rule {'epliteerror':
    path => "${etherpad_lite::base_log_dir}/${etherpad_lite::ep_user}/error.log",
    rotate => 7,
    compress => true,
    copytruncate => true,
    missingok => true,
    delaycompress => true,
    rotate_every => 'day',
    ifempty => false,
    require => Service['etherpad-lite']
  }

  logrotate::rule {'epliteaccess':
    path => "${etherpad_lite::base_log_dir}/${etherpad_lite::ep_user}/access.log",
    rotate => 7,
    compress => true,
    copytruncate => true,
    missingok => true,
    delaycompress => true,
    rotate_every => 'day',
    ifempty => false,
    require => Service['etherpad-lite']
  }
}
