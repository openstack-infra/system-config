# == Define: site
#

define lodgeit::site(
  $port,
  $vhost_name="paste.${name}.org",
  $database_host = 'localhost',
  $database_user = 'openstack',
  $database_password = '',
  $database_name = 'openstack',
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
      source => "puppet:///lodgeit/${image}",
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

  cron { "update_backup_${name}":
    ensure => absent
  }

  service { "${name}-paste":
    ensure   => running,
    provider => upstart,
    require  => Service['apache2'],
  }
}
