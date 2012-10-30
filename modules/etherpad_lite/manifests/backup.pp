# == Class: etherpad_lite::backup
#
class etherpad_lite::backup (
  $minute = '0',
  $hour = '0',
  $day = '*',
  $dest = "${etherpad_lite::base_log_dir}/${etherpad_lite::ep_user}/db.sql.gz",
  $rotation = 'daily',
  $num_backups = '30'
) {

  cron { 'eplitedbbackup':
    ensure  => present,
    command => "/usr/bin/mysqldump --defaults-file=/etc/mysql/debian.cnf --opt etherpad-lite | gzip -9 > ${dest}",
    minute  => $minute,
    hour    => $hour,
    weekday => $day,
    require => Package['mysql-server'],
  }

  include logrotate
  logrotate::file { 'eplitedb':
    log     => $dest,
    options => [
      'nocompress',
      "rotate ${num_backups}",
      $rotation,
    ],
    require => Cron['eplitedbbackup'],
  }
}
