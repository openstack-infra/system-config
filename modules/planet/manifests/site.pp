define planet::site($git_url, $vhost_name="planet.${name}.org") {

  include apache
  include remove_nginx

  apache::vhost { $vhost_name:
    port => 80,
    priority => '50',
    docroot => "/srv/planet/${name}",
    require => File["/srv/planet"],
  }

  vcsrepo { "/var/lib/planet/${name}":
    ensure => present,
    provider => git,
    source => $git_url,
    require => File['/var/lib/planet'],
  }

  cron { "update_planet_${name}":
    user => root,
    minute => "*/5",
    command => "date >> /var/log/planet/${name}.log && cd /var/lib/planet/${name} && git pull -q --ff-only && planet /var/lib/planet/${name}/planet.ini >> /var/log/planet/${name}.log 2>&1"
  }

}
