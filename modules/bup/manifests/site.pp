# Define: bup::site
#
define bup::site(
  $backup_user,
  $backup_server,
  $backup_db = false
) {
  if ($backup_db) {
    $backup_script = '/usr/local/bup/run-bup-db.sh'
  } else {
    $backup_script = '/usr/local/bup/run-bup.sh'
  }
  cron { "bup-${name}":
    user    => 'root',
    hour    => '5',
    minute  => '37',
    command => "${backup_script} ${backup_user}@${backup_server}",
  }
}
