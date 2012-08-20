class launchpad_sync(
  $user='gerrit2',
  $script_user='update',
  $script_key_file='/home/gerrit2/.ssh/id_rsa',
  $script_logging_conf,
  $site,
  $root_team
) {

  include mysql
  include mysql::python

  $packages = [
               "python-openid",       # for launchpad sync script
               "python-launchpadlib", # for launchpad sync script
               ]

  package { $packages:
    ensure => present,
  }

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
    command => "sleep $((RANDOM\\%60+60)) && timeout -k 5m 8h python /usr/local/bin/update_gerrit_users.py ${script_user} ${script_key_file} ${site} ${root_team} ${script_logging_conf}",
    require => File['/usr/local/bin/update_gerrit_users.py'],
  }

}
