class gerrit::remotes($upstream_projects) {
    cron { "gerritfetchremotes":
      user => gerrit2,
      minute => "*/30",
      command => 'sleep $((RANDOM\%60+90)) && python /usr/local/gerrit/scripts/fetch_remotes.py',
      require => File['/usr/local/gerrit/scripts'],
    }

    file { '/home/gerrit2/remotes.config':
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      content => template('gerrit/remotes.config.erb'),
      replace => 'true',
      require => User["gerrit2"]
    }
}
