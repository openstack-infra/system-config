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
    home       => '/var/lib/jenkins',
    gid        => 'jenkins',
    shell      => '/bin/bash',
    membership => 'minimum',
    groups     => [],
    require    => Group['jenkins'],
  }

  file { '/var/lib/jenkins':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => User['jenkins'],
  }

  file { '/var/lib/jenkins/.pip':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.gitconfig':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => 'puppet:///modules/jenkins/gitconfig',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.ssh':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['/var/lib/jenkins'],
  }

  ssh_authorized_key { 'jenkins-master-2014-04-24':
    ensure  => present,
    user    => 'jenkins',
    type    => 'ssh-rsa',
    key     => $ssh_key,
    require => File['/var/lib/jenkins/.ssh'],
  }
  ssh_authorized_key { '/var/lib/jenkins/.ssh/authorized_keys':
    ensure  => absent,
    user    => 'jenkins',
  }

  #NOTE: not all distributions have default bash files in /etc/skel
  if ($::osfamily == 'Debian') {

    file { '/var/lib/jenkins/.bashrc':
      ensure  => present,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      source  => '/etc/skel/.bashrc',
      replace => false,
      require => File['/var/lib/jenkins'],
    }

    file { '/var/lib/jenkins/.bash_logout':
      ensure  => present,
      source  => '/etc/skel/.bash_logout',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File['/var/lib/jenkins'],
    }

    file { '/var/lib/jenkins/.profile':
      ensure  => present,
      source  => '/etc/skel/.profile',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File['/var/lib/jenkins'],
    }

  }

  file { '/var/lib/jenkins/.ssh/config':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    require => File['/var/lib/jenkins/.ssh'],
    source  => 'puppet:///modules/jenkins/ssh_config',
  }

  file { '/var/lib/jenkins/.gnupg':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.gnupg/pubring.gpg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['/var/lib/jenkins/.gnupg'],
    source  => 'puppet:///modules/jenkins/pubring.gpg',
  }

  file { '/var/lib/jenkins/.config':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.m2':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.m2/settings.xml':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => File['/var/lib/jenkins/.m2'],
    source  => 'puppet:///modules/jenkins/settings.xml',
  }

}
