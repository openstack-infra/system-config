# == Class: jenkins::cgroups
#
class jenkins::cgroups {

  package { 'cgroup-bin':
    ensure => present,
  }

  file { '/etc/cgconfig.conf':
    ensure  => present,
    replace => true,
    owner   => 'root',
    group   => 'jenkins',
    mode    => '0644',
    content => template('jenkins/cgconfig.erb'),
  }

  file { '/etc/cgrules.conf':
    ensure  => present,
    replace => true,
    owner   => 'root',
    group   => 'jenkins',
    mode    => '0644',
    source  => 'puppet:///modules/jenkins/cgroups/cgrules.conf',
  }

  service { 'cgconfig':
    ensure    => running,
    enable    => true,
    require   => Package['cgroup-bin'],
    subscribe => File['/etc/cgconfig.conf'],
  }

  service { 'cgred':
    ensure    => running,
    enable    => true,
    require   => Package['cgroup-bin'],
    subscribe => File['/etc/cgrules.conf'],
  }
}
