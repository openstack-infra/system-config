# == Class: gerrit::cron
#
class gerrit::cron {

  cron { 'gerrit_repack':
    user        => 'gerrit2',
    weekday     => '0',
    hour        => '4',
    minute      => '7',
    command     => 'find /home/gerrit2/review_site/git/ -type d -name "*.git" -print -exec git --git-dir="{}" repack -afd \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'expireoldreviews':
    ensure      => 'absent',
    user        => 'gerrit2',
  }

  cron { 'removedbdumps':
    ensure      => 'absent',
    user        => 'gerrit2',
  }
}
