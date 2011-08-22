class reprepro {

  package { "reprepro": ensure => "latest" }

  file { "/srv":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => directory,
  }

  file {"/srv/packages":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => directory,
    require => File["/srv"],
  }

  file {"/srv/packages/trunk":
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => directory,
    require => [File["/srv/packages"], User[jenkins]]
  }

  file {"/srv/packages/trunk/conf":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => directory,
    require => File["/srv/packages/trunk"],
  }

  file {"/srv/packages/trunk/conf/distributions":
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/reprepro/distributions",
  }

  file {"/srv/packages/diablo":
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => directory,
    require => [File["/srv/packages"], User[jenkins]]
  }

  file {"/srv/packages/diablo/conf":
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => directory,
    require => File["/srv/packages/diablo"],
  }

  file {"/srv/packages/diablo/conf/distributions":
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/reprepro/distributions",
  }

}
