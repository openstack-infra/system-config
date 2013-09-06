# == Define: mysql_backup::backup_remote
#
# Arguments determine when backups should be taken, where they should
# be located, and how often they shouled be rotated. Additionally
# provide remote DB authentication details for that DB to be backed up.
# This define assumes that the mysqldump command is installed under
# /usr/bin. All reachable DBs and tables will be backed up.
#
define mysql_backup::backup_remote (
  $database_host,
  $database_user,
  $database_password,
  $minute = '0',
  $hour = '0',
  $day = '*',
  $dest_dir = '/var/backups/mysql_backups',
  $rotation = 'daily',
  $num_backups = '30'
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
  $defaults_file = "/root/.${name}_db.cnf"
  file { $defaults_file:
    ensure  => present,
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
    content => template('mysql_backup/my.cnf.erb'),
  }

  if ! defined(Package['mysql-client']) {
    package { 'mysql-client':
      ensure => present,
    }
  }

  cron { "${name}-backup":
    ensure  => present,
    command => "/usr/bin/mysqldump --defaults-file=${defaults_file} --opt --ignore-table mysql.event --all-databases | gzip -9 > ${dest_dir}/${name}.sql.gz",
    minute  => $minute,
    hour    => $hour,
    weekday => $day,
    require => [
      File[$dest_dir],
      File[$defaults_file],
    ],
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
