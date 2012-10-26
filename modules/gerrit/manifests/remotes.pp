# == Class: gerrit::remotes
#
class gerrit::remotes($ensure=present) {
    cron { 'gerritfetchremotes':
      ensure  => $ensure,
      user    => 'gerrit2',
      minute  => '*/30',
      command => 'sleep $((RANDOM\%60+90)) && python \
        /usr/local/gerrit/scripts/fetch_remotes.py',
      require => File['/usr/local/gerrit/scripts'],
    }

    file { '/home/gerrit2/remotes.config':
      ensure => absent,
    }
}
