# == Class: livegrep
#
class livegrep() {
  user { 'livegrep':
    ensure     => present,
    home       => '/home/livegrep',
    shell      => '/bin/bash',
    gid        => 'livegrep',
    managehome => true,
    require    => Group['livegrep'],
  }

  group { 'livegrep':
    ensure => present,
  }

  vcsrepo { '/opt/livegrep':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/nelhage/livegrep',
  }

  $packages = [
    'libjson0-dev',
    'libgflags-dev',
    'libgit2-dev',
    'libboost-dev',
    'libsparsehash-dev',
    'build-essential',
    'libgoogle-perftools-dev',
    'libssl-dev',
    'libboost-filesystem-dev',
    'libboost-system-dev',
    'mercurial',
  ]

  package { $packages:
    ensure => present,
  }

  package { 'golang':
    ensure => present,
  }

  exec { 'make livegrep':
    command     => '/usr/bin/make -j8',
    cwd         => '/opt/livegrep',
    subscribe   => Vcsrepo['/opt/livegrep'],
    refreshonly => true,
    require     => Package[$packages],
  }

  exec { 'go get':
    command     => '/usr/bin/go get',
    cwd         => '/opt/livegrep/livegrep',
    environment => 'GOPATH=/home/livegrep/.gopath',
    subscribe   => Vcsrepo['/opt/livegrep'],
    refreshonly => true,
    require     => Package['golang'],
  }

  exec { 'go build':
    command     => '/usr/bin/go build',
    cwd         => '/opt/livegrep/livegrep',
    environment => 'GOPATH=/home/livegrep/.gopath',
    subscribe   => Vcsrepo['/opt/livegrep'],
    refreshonly => true,
    require     => [
      Package['golang'],
      Exec['go get'],
    ],
  }

  $openstack_repos = [
    'nova',
    'cinder',
    'glance',
    'swift',
    'keystone',
    'marconi',
    'barbican',
  ]

  file { '/home/livegrep/repos':
    ensure => directory,
  }

  define openstack_repo {
    vcsrepo { "/home/livegrep/repos/$name":
      ensure   => latest,
      provider => git,
      revision => 'master',
      source   => "https://github.com/openstack/$name",
    }
  }

  openstack_repo { $openstack_repos:
  }

  file { '/etc/livegrep':
    ensure => directory,
  }

  file { '/etc/livegrep/codesearch.json':
    ensure  => present,
    owner   => 'livegrep',
    group   => 'livegrep',
    mode    => '0775',
    require => User['livegrep'],
    content => template('livegrep/codesearch.json.erb'),
  }

  file { '/etc/livegrep/livegrep.json':
    ensure  => present,
    owner   => 'livegrep',
    group   => 'livegrep',
    mode    => '0775',
    require => User['livegrep'],
    source  => 'puppet:///modules/livegrep/livegrep.json',
  }

  file { '/etc/init.d/codesearch':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/livegrep/codesearch.init',
  }

  file { '/etc/init.d/livegrep':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/livegrep/livegrep.init',
  }

  service { 'codesearch':
    enable     => true,
    hasrestart => true,
    require    => [
      File['/etc/livegrep/codesearch.json'],
      File['/etc/init.d/codesearch'],
      Vcsrepo["/home/livegrep/repos/$openstack_repos"],
      Exec['make livegrep'],
    ],
  }

  service { 'livegrep':
    enable     => true,
    hasrestart => true,
    require    => [
      File['/etc/livegrep/livegrep.json'],
      Service['codesearch'],
    ],
  }
}
