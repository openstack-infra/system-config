# == Class: etherpad_lite::backup
#
class etherpad_lite::backup (
  $minute = '0',
  $hour = '0',
  $day = '*',
  $rotation = 'daily',
  $num_backups = '30'
) {

  cron { 'eplitedbbackup':
    ensure  => absent,
  }

  include logrotate
  logrotate::file { 'eplitedb':
    log     => $dest,
    options => [
      'nocompress',
      "rotate ${num_backups}",
      $rotation,
    ],
  }
}
