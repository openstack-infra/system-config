define doc_server::site {

  file { "/etc/nginx/sites-available/${name}":
    ensure => 'present',
    content => template("doc_server/nginx.erb"),
    replace => 'true',
    require => Package[nginx],
  }

  file { "/etc/nginx/sites-enabled/${name}":
    ensure => link,
    target => "/etc/nginx/sites-available/${name}",
    require => Package[nginx],
  }
}
