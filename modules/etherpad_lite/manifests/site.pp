class etherpad_lite::site (
  $dbType      = 'mysql',
  $listen_addr = '127.0.0.1',
  $listen_port = '9001'
) {

  include etherpad_lite

  if $dbType == 'mysql' {
    include etherpad_lite::mysql_settings
    $dbSettings = "
\"user\" : \"${etherpad_lite::mysql_settings::ep_user}\",
\"password\" : \"${etherpad_lite::mysql_settings::eppasswd}\",
\"host\" : \"${etherpad_lite::mysql_settings::host}\",
\"database\" : \"${etherpad_lite::mysql_settings::database}\""

    service { 'etherpad-lite':
      enable    => true,
      ensure    => running,
      subscribe => File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"],
      require   => Class['etherpad_lite::mysql'],
    }
  }
  else {
    $dbSettings = '"filename" : "../var/dirty.db"'

    service { 'etherpad-lite':
      enable    => true,
      ensure    => running,
      subscribe => File["${etherpad_lite::base_install_dir}/etherpad-lite/settings.json"],
    }
  }

  file { "${etherpad_lite::base_install_dir}/etherpad-lite/settings.json":
    ensure  => 'present',
    content => template('etherpad_lite/settings.erb'),
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    mode    => 0600,
    require => Class['etherpad_lite']
  }

  file { "${etherpad_lite::base_install_dir}/etherpad-lite/static/custom/pad.js":
    ensure  => 'present',
    source  => 'puppet:///modules/etherpad_lite/pad.js',
    owner   => $etherpad_lite::ep_user,
    group   => $etherpad_lite::ep_user,
    require => Class['etherpad_lite']
  }

}
