# == Class: jenkins::cgroups
#
class jenkins::cgroups {

  include jenkins::params

  package { 'cgroups':
    ensure => present,
    name   => $::jenkins::params::cgroups_package,
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

  # Starting with Ubuntu Quantal (12.10) cgroup-bin dropped its upstart jobs.
  if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease >= 12.10 {

    file { '/etc/init/cgconfig.conf':
      ensure  => present,
      replace => true,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/jenkins/cgroups/upstart_cgconfig',
    }

    file { '/etc/init/cgred.conf':
      ensure  => present,
      replace => true,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/jenkins/cgroups/upstart_cgred',
    }

  }

  service { 'cgconfig':
    ensure    => running,
    enable    => true,
    require   => Package['cgroups'],
    subscribe => File['/etc/cgconfig.conf'],
  }

  service { 'cgred':
    ensure    => running,
    enable    => true,
    require   => Package['cgroups'],
    subscribe => File['/etc/cgrules.conf'],
  }
}
