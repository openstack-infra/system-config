class launchpad_sync(
  $root_team,
  $script_logging_conf,
  $site,
  $script_key_file = '/home/gerrit2/.ssh/id_rsa',
  $script_user = 'update',
  $user = 'gerrit2'
) {
  include mysql
  include mysql::python

  $packages = [
    'python-openid',       # for launchpad sync script
    'python-launchpadlib', # for launchpad sync script
  ]

  package { $packages:
    ensure => present,
  }

  file { '/usr/local/bin/update_gerrit_users.py':
    ensure  => present,
    group   => 'root',
    mode    => '0755',
    owner   => 'root',
    source  => 'puppet:///modules/launchpad_sync/update_gerrit_users.py',
  }

  cron { 'sync_launchpad_users':
    user    => $user,
    minute  => '*/15',
    command => "sleep $((RANDOM\\%60+60)) && timeout -k 5m 8h python /usr/local/bin/update_gerrit_users.py ${script_user} ${script_key_file} ${site} ${root_team} ${script_logging_conf}",
    require => File['/usr/local/bin/update_gerrit_users.py'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
