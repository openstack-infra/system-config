define planet::site(
  $git_url,
  $vhost_name = "planet.${name}.org"
) {
  include apache

  apache::vhost { $vhost_name:
    docroot  => "/srv/planet/${name}",
    port     => 80,
    priority => '50',
    require  => File['/srv/planet'],
  }

  vcsrepo { "/var/lib/planet/${name}":
    ensure   => present,
    provider => git,
    require  => File['/var/lib/planet'],
    source   => $git_url,
  }

  cron { "update_planet_${name}":
    command => "date >> /var/log/planet/${name}.log && cd /var/lib/planet/${name} && git pull -q --ff-only && planet /var/lib/planet/${name}/planet.ini >> /var/log/planet/${name}.log 2>&1",
    minute  => '*/5',
    user    => 'root',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
