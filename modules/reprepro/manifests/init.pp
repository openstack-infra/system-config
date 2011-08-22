class reprepro {

  package { "reprepro": ensure => "latest" }

  file { "/srv":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => directory,
  }

  file {"/srv/packages":
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => directory,
    require => [File["/srv"], User[jenkins]]
  }

  file {"/srv/packages/conf":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => directory,
    require => File["/srv/packages"],
  }

  file {"/srv/packages/conf/distributions":
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/reprepro/distributions",
  }

}
