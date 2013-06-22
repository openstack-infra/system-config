# == Class: jenkins::cgroups
#
class jenkins::cgroups {

  include jenkins::params

  if ($::jenkins::params::cgroups_tools_package != '') {
    package { 'cgroups-tools':
      ensure => present,
      name   => $::jenkins::params::cgroups_tools_package,
    }
  }
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
  if $::osfamily == 'Debian' {

    if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease >= '12.10' {

      file { '/etc/init/cgconfig.conf':
        ensure  => present,
        replace => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/jenkins/cgroups/upstart_cgconfig',
      }

      file { '/etc/init.d/cgconfig':
        ensure => link,
        target => '/lib/init/upstart-job',
      }

      file { '/etc/init/cgred.conf':
        ensure  => present,
        replace => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/jenkins/cgroups/upstart_cgred',
      }

      file { '/etc/init.d/cgred':
        ensure => link,
        target => '/lib/init/upstart-job',
      }

    } else {

      file { '/etc/init/cgconfig.conf':
        ensure  => present,
      }

      file { '/etc/init/cgred.conf':
        ensure  => present,
      }

    }

  }

  service { 'cgconfig':
    ensure    => running,
    enable    => true,
    require   => $::jenkins::params::cgconfig_require,
    subscribe => File['/etc/cgconfig.conf'],
  }

  service { 'cgred':
    ensure    => running,
    enable    => true,
    require   => $::jenkins::params::cgred_require,
    subscribe => File['/etc/cgrules.conf'],
  }
}
