# == Class: jenkins::jenkinsuser
#
class jenkins::jenkinsuser(
  $ssh_key = '',
  $ensure = present,
) {

  group { 'jenkins':
    ensure => present,
  }

  user { 'jenkins':
    ensure     => present,
    comment    => 'Jenkins User',
    home       => '/home/jenkins',
    gid        => 'jenkins',
    shell      => '/bin/bash',
    membership => 'minimum',
    groups     => [],
    require    => Group['jenkins'],
  }

  file { '/home/jenkins':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => User['jenkins'],
  }

  file { '/home/jenkins/.pip':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.ssh':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.ssh/config':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    require => File['/home/jenkins/.ssh'],
    source  => 'puppet:///modules/jenkins/ssh_config',
  }

  ssh_authorized_key { 'jenkins-master-2014-04-24':
    ensure  => present,
    user    => 'jenkins',
    type    => 'ssh-rsa',
    key     => $ssh_key,
    require => File['/home/jenkins/.ssh'],
  }

  ssh_authorized_key { '/home/jenkins/.ssh/authorized_keys':
    ensure  => absent,
    user    => 'jenkins',
  }

  #NOTE: not all distributions have default bash files in /etc/skel
  if ($::osfamily == 'Debian') {

    file { '/home/jenkins/.bashrc':
      ensure  => present,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      source  => '/etc/skel/.bashrc',
      replace => false,
      require => File['/home/jenkins'],
    }

    file { '/home/jenkins/.bash_logout':
      ensure  => present,
      source  => '/etc/skel/.bash_logout',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File['/home/jenkins'],
    }

    file { '/home/jenkins/.profile':
      ensure  => present,
      source  => '/etc/skel/.profile',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File['/home/jenkins'],
    }

  }

  file { '/home/jenkins/.config':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['/home/jenkins'],
  }

}
