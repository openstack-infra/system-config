define planet::site($git_url) {

  file { "/etc/nginx/sites-available/planet-${name}":
    ensure => present,
    content => template("planet/nginx.erb"),
    replace => true,
    require => Package[nginx],
    notify => Service[nginx]
  }

  file { "/etc/nginx/sites-enabled/planet-${name}":
    ensure => link,
    target => "/etc/nginx/sites-available/planet-${name}",
    require => Package[nginx],
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
