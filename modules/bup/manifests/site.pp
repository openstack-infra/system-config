# Define: bup::site
#
define bup::site(
  $backup_user,
  $backup_server
) {
  cron { "bup-${name}":
    user    => 'root',
    hour    => '5',
    minute  => '37',
    command => "tar -X /etc/bup-excludes -cPf - / | bup split -r ${backup_user}@${backup_server}: -n root -q",
  }
}
