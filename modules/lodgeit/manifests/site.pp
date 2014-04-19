# == Define: site
#

define lodgeit::site(
  $port,
  $mysql_password,
  $mysql_host = 'localhost',
  $mysql_user = "${name}",
  $mysql_db_name = "${name}",
  $vhost_name="paste.${name}.org",
  $image='') {

  include apache

  apache::vhost::proxy { $vhost_name:
    port    => 80,
    dest    => "http://localhost:${port}",
    require => File["/srv/lodgeit/${name}"],
  }

  file { "/etc/init/${name}-paste.conf":
    ensure  => present,
    content => template('lodgeit/upstart.erb'),
    replace => true,
    require => Package['apache2'],
    notify  => Service["${name}-paste"],
  }

  file { "/srv/lodgeit/${name}":
    ensure  => directory,
    recurse => true,
    source  => '/tmp/lodgeit-main',
  }

  if $image != '' {
    file { "/srv/lodgeit/${name}/lodgeit/static/${image}":
      ensure => present,
      source => "puppet:///modules/lodgeit/${image}",
    }
  }

  file { "/srv/lodgeit/${name}/manage.py":
    ensure  => present,
    mode    => '0755',
    replace => true,
    content => template('lodgeit/manage.py.erb'),
    notify  => Service["${name}-paste"],
  }

  file { "/srv/lodgeit/${name}/lodgeit/views/layout.html":
    ensure  => present,
    replace => true,
    content => template('lodgeit/layout.html.erb'),
  }

  service { "${name}-paste":
    ensure    => running,
    provider  => upstart,
    require   => Service['apache2'],
  }

  mysql_backup::backup_remote { "pastebin-${mysql_db_name}":
    database_host     => $mysql_host,
    database_user     => $mysql_user,
    database_password => $mysql_password,
    require           => Class['lodgeit'],
  }

  include bup
  bup::site { "rs-ord-${name}":
    backup_user   => 'bup-pastebin',
    backup_server => 'ci-backup-rs-ord.openstack.org',
  }
}
