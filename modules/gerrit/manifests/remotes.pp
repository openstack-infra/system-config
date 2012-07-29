class gerrit::remotes($ensure=present) {
    cron { "gerritfetchremotes":
      user => gerrit2,
      ensure => $ensure,
      minute => "*/30",
      command => 'sleep $((RANDOM\%60+90)) && python /usr/local/gerrit/scripts/fetch_remotes.py',
      require => File['/usr/local/gerrit/scripts'],
    }

    file { '/home/gerrit2/remotes.config':
      ensure => absent
    }
}
