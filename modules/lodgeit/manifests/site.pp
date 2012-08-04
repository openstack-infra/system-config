define lodgeit::site($vhost_name="paste.$name.org", $port, $image="") {

  include remove_nginx

  apache::vhost::proxy { $vhost_name:
    port => 80,
    dest => "http://localhost:$port",
    require => File["/srv/lodgeit/${name}"],
  }

  file { "/etc/init/${name}-paste.conf":
    ensure => 'present',
    content => template("lodgeit/upstart.erb"),
    replace => 'true',
    require => Package[nginx],
    notify => Service["${name}-paste"]
  }

  file { "/srv/lodgeit/${name}":
    ensure => directory,
    recurse => true,
    source => "/tmp/lodgeit-main"
  }

  if $image != '' {
    file { "/srv/lodgeit/${name}/lodgeit/static/${image}":
      ensure => present,
      source => "puppet:///lodgeit/${image}"
    }
  }

  file { "/srv/lodgeit/${name}/manage.py":
    mode => 755,
    replace => true,
    content => template("lodgeit/manage.py.erb"),
    notify => Service["${name}-paste"]
  }

  file { "/srv/lodgeit/${name}/lodgeit/views/layout.html":
    replace => true,
    content => template("lodgeit/layout.html.erb")
  }

  exec { "create_database_${name}":
    command => "drizzle --user=root -e \"create database if not exists ${name};\"",
    path => "/bin:/usr/bin",
    unless => "drizzle --disable-column-names -r --batch -e \"show databases like 'openstack'\" | grep openstack >/dev/null",
    require => Service["drizzle"]
  }

# create a backup .sql file in git

  exec { "create_db_backup_${name}":
    command => "touch ${name}.sql && git add ${name}.sql && git commit -am \"Initial commit for ${name}\"",
    cwd => "/var/backups/lodgeit_db/",
    path => "/bin:/usr/bin",
    onlyif => "test ! -f /var/backups/lodgeit_db/${name}.sql"
  }

# cron to take a backup and commit it in git

  cron { "update_backup_${name}":
    user => root,
    hour => 6,
    minute => 23,
    command => "sleep $((RANDOM\\%60+60)) && cd /var/backups/lodgeit_db && drizzledump -uroot ${name} > ${name}.sql && git commit -qam \"Updating DB backup for ${name}\""
  }

  service { "${name}-paste":
    provider => upstart,
    ensure => running,
    require => [Service["drizzle", "nginx"], Exec["create_database_${name}"]]
  }

}
