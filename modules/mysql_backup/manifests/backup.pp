# == Define: mysql_backup::backup
#
# Arguments determine when backups should be taken, where they should
# be located, and how often they shouled be rotated. The namevar
# of the define must be the name of the database to backup.
# This define assumes that the mysqldump command is installed under
# /usr/bin.
#
define mysql_backup::backup (
  $minute = '0',
  $hour = '0',
  $day = '*',
  $dest_dir = '/var/backups/mysql_backups',
  $rotation = 'daily',
  $num_backups = '30',
  $defaults_file = '/etc/mysql/debian.cnf'
) {
  # Wrap in check as there may be mutliple backup defines backing
  # up to the same dir.
  if ! defined(File[$dest_dir]) {
    file { $dest_dir:
      ensure => directory,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }
  }

  cron { "${name}-backup":
    ensure  => present,
    command => "/usr/bin/mysqldump --defaults-file=${defaults_file} --opt --all-databases | gzip -9 > ${dest_dir}/${name}.sql.gz",
    minute  => $minute,
    hour    => $hour,
    weekday => $day,
    require => File[$dest_dir],
  }

  include logrotate
  logrotate::file { "${name}-rotate":
    log     => "${dest_dir}/${name}.sql.gz",
    options => [
      'nocompress',
      "rotate ${num_backups}",
      $rotation,
    ],
    require => Cron["${name}-backup"],
  }
}
