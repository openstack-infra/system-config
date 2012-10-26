# == Class: jenkins::jenkinsuser
#
class jenkins::jenkinsuser(
  $ssh_key,
  $ensure = present,
  $sudo = false,
) {

  group { 'jenkins':
    ensure => present,
  }

  if ($sudo == true) {
    $groups = ['sudo', 'admin']
  } else {
    $groups = []
  }

  user { 'jenkins':
    ensure     => present,
    comment    => 'Jenkins User',
    home       => '/home/jenkins',
    gid        => 'jenkins',
    shell      => '/bin/bash',
    membership => 'minimum',
    groups     => $groups,
    require    => Group['jenkins']
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
    require => File['jenkinshome'],
  }

  file { '/home/jenkins/.pip/pip.conf':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => 'puppet:///modules/jenkins/pip.conf',
    require => File['jenkinspipdir'],
  }

  file { '/home/jenkins/.pydistutils.cfg':
    ensure  => absent,
    require => File['jenkinshome'],
  }

  file { '/home/jenkins/.gitconfig':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => 'puppet:///modules/jenkins/gitconfig',
    require => File['jenkinshome'],
  }

  file { '/home/jenkins/.ssh':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['jenkinshome'],
  }

  file { '/home/jenkins/.ssh/authorized_keys':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => $ssh_key,
    require => File['jenkinssshdir'],
  }

  file { '/home/jenkins/.bashrc':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => '/etc/skel/.bashrc',
    replace => false,
  }

  file { '/home/jenkins/.bash_logout':
    ensure  => present,
    source  => '/etc/skel/.bash_logout',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    replace => false,
  }

  file { '/home/jenkins/.profile':
    ensure  => present,
    source  => '/etc/skel/.profile',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    replace => false,
  }

  file { '/home/jenkins/.ssh/config':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    require => File['jenkinssshdir'],
    source  => 'puppet:///modules/jenkins/ssh_config',
  }

  file { '/home/jenkins/.gnupg':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File['jenkinshome'],
  }

  file { '/home/jenkins/.gnupg/pubring.gpg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['jenkinsgpgdir'],
    source  => 'puppet:///modules/jenkins/pubring.gpg',
  }

  file { '/home/jenkins/.config':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['jenkinshome'],
  }
}
