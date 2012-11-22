# == Class: gerrit::cron
#
class gerrit::cron(
  $script_user = 'update',
  $script_key_file = '/home/gerrit2/.ssh/id_rsa'
) {

  cron { 'expireoldreviews':
    user    => 'gerrit2',
    hour    => '6',
    minute  => '3',
    command => "python /usr/local/bin/expire-old-reviews ${script_user} ${script_key_file}",
    require => Class['jeepyb'],
  }

  cron { 'gerrit_repack':
    user        => 'gerrit2',
    weekday     => '0',
    hour        => '4',
    minute      => '7',
    command     => 'find /home/gerrit2/review_site/git/ -type d -name "*.git" -print -exec git --git-dir="{}" repack -afd \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'removedbdumps':
    user        => 'gerrit2',
    hour        => '5',
    minute      => '1',
    command     => 'find /home/gerrit2/dbupdates/ -name "*.sql.gz" -mtime +30 -exec rm -f {} \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }
}
