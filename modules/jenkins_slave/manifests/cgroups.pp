class jenkins_slave::cgroups {

  package { 'cgroup-bin':
    ensure => present
  }

  file { '/etc/cgconfig.conf':
    ensure  => present,
    replace => true,
    owner   => root,
    mode    => 0644,
    content => template('jenkins_slave/cgconfig.erb')
  }

  file { '/etc/cgrules.conf':
    ensure  => present,
    replace => true,
    owner   => root,
    mode    => 0644,
    source  => 'puppet:///modules/jenkins_slave/cgroups/cgrules.conf'
  }

  service { 'cgconfig':
    enable    => true,
    ensure    => running,
    require   => Package['cgroup-bin'],
    subscribe => File['/etc/cgconfig.conf']
  }

  service { 'cgred':
    enable    => true,
    ensure    => running,
    require   => Package['cgroup-bin'],
    subscribe => File['/etc/cgrules.conf']
  }

}
