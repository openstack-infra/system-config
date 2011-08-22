class apt_server {

  $packages = ["reprepro",
               "nginx"]

  package { $packages: ensure => "latest" }

  file { "/etc/nginx/sites-available/default":
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/apt_server/packages",
    replace => 'true',
    require => Package[nginx],
  }

  file { "/etc/nginx/sites-enabled/default":
    ensure => link,
    target => "/etc/nginx/sites-available/default",
    require => Package[nginx],
  }

  file { "/srv":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => directory,
  }

  file {"/srv/packages":
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => directory,
    require => File["/srv"],
  }

  file {"/srv/packages/conf":
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => directory,
    require => [File["/srv/packages"], User[jenkins]]
  }

  file {"/srv/packages/conf/distributions":
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/apt_server/distributions",
  }

  service { 'nginx':
    name       => 'nginx',
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require => Package['nginx'],
  }

}
