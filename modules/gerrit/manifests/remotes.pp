# == Class: gerrit::remotes
#
class gerrit::remotes($ensure=present) {
    cron { 'gerritfetchremotes':
      ensure  => $ensure,
      user    => 'gerrit2',
      minute  => '*/30',
      command => 'sleep $((RANDOM\%60+90)) && /usr/local/bin/fetch-remotes',
      require => Class['jeepyb'],
    }

    file { '/home/gerrit2/remotes.config':
      ensure => absent,
    }
}
