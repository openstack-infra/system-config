class launchpad_sync(
  $user,
  $script_user,
  $script_key_file,
  $site,
  $root_team
) {

  file { '/usr/local/bin/update_gerrit_users.py':
    owner => 'root',
    group => 'root',
    mode => 755,
    source => "puppet:///modules/launchpad_sync/update_gerrit_users.py",
    ensure => present,
  }

  cron { "sync_launchpad_users":
    user => $user,
    minute => "*/15",
    command => "sleep $((RANDOM\\%60+60)) && python /usr/local/bin/update_gerrit_users.py ${script_user} ${script_key_file} ${site} ${root_team}",
    require => File['/usr/local/bin/update_gerrit_users.py'],
  }

}
