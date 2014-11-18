# == Class: dedupe::dedupe_path
#
# creates a cron job for deduping files on a path
define dedupe::dedupe_path(
  $path = $name,
){
  include dedupe
  cron { "dedupe-${name}":
    command => "fdupes -r ${name} | /usr/local/bin/dedupe.py",
    user    => 'root',
    hour    => '4',
    minute  => '0',
  }
}
