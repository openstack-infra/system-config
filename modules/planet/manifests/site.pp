define planet::site($git_url) {

  file { "/etc/nginx/sites-available/planet-${name}":
    ensure => present,
    content => template("planet/nginx.erb"),
    replace => true,
    require => Package[nginx]
  }

  file { "/etc/nginx/sites-enabled/planet-${name}":
    ensure => link,
    target => "/etc/nginx/sites-available/planet-${name}",
    require => Package[nginx],
  }

# if we already have the mercurial repo the pull updates

  exec { "update_${name}_planet":
    command => "git pull",
    cwd => "/var/lib/planet/${name}",
    path => "/bin:/usr/bin",
    onlyif => "test -d /var/lib/planet/${name}"
  }

# otherwise get a new clone of it

  exec { "create_${name}_planet":
    command => "git clone ${git_url} /var/lib/planet/${name}",
    path => "/bin:/usr/bin",
    onlyif => "test ! -d /var/lib/planet/${name}"
  }

  cron { "update_planet_${name}":
    user => root,
    minute => 3,
    command => "planet /var/lib/planet/${name}.ini"
  }

}
