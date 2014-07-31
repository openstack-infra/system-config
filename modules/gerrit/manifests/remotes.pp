# == Class: gerrit::remotes
#
class gerrit::remotes($ensure=present) {
    cron { 'gerritfetchremotes':
      ensure  => $ensure,
      user    => 'gerrit2',
      minute  => '*/30',
      command => 'sleep $((RANDOM\%60+90)) && /usr/local/bin/manage-projects -v | tee /var/log/manage_projects.log | logger -t "manage-projects"',
      require => [Class['jeepyb'], File['/var/lib/jeepyb']],
    }

    file { '/var/lib/jeepyb':
      ensure  => directory,
      owner   => 'gerrit2',
      require => User['gerrit2'],
    }

    file { '/home/gerrit2/remotes.config':
      ensure => absent,
    }

    include logrotate
    logrotate::file { 'manage_projects.log':
      log     => '/var/log/manage_projects.log',
      options => [
        'compress',
        'missingok',
        'rotate 30',
        'daily',
        'notifempty',
      ],
      require => Cron['gerritfetchremotes'],
    }
}
