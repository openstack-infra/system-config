# == Class: jenkins::jenkinsuser
#
class jenkins::jenkinsuser(
  $ssh_key = '',
  $ensure = present,
  $sudo = false,
  $home = '/home/jenkins',
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
    home       => $home,
    gid        => 'jenkins',
    shell      => '/bin/bash',
    membership => 'minimum',
    groups     => $groups,
    require    => Group['jenkins'],
  }

  file { $home:
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => User['jenkins'],
  }

  file { "${home}/.pip":
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File[$home],
  }

  file { "${home}/.gitconfig":
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => 'puppet:///modules/jenkins/gitconfig',
    require => File[$home],
  }

  file { "${home}/.ssh":
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File[$home],
  }

  file { "${home}/.ssh/authorized_keys":
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => $ssh_key,
    require => File["${home}/.ssh"],
  }

  #NOTE: not all distributions have default bash files in /etc/skel
  if ($::osfamily == 'Debian') {

    file { "${home}/.bashrc":
      ensure  => present,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      source  => '/etc/skel/.bashrc',
      replace => false,
      require => File[$home],
    }

    file { "${home}/.bash_logout":
      ensure  => present,
      source  => '/etc/skel/.bash_logout',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File[$home],
    }

    file { "${home}/.profile":
      ensure  => present,
      source  => '/etc/skel/.profile',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File[$home],
    }

  }

  file { "${home}/.ssh/config":
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    require => File["${home}/.ssh"],
    source  => 'puppet:///modules/jenkins/ssh_config',
  }

  file { "${home}/.gnupg":
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File[$home],
  }

  file { "${home}/.gnupg/pubring.gpg":
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File["${home}/.gnupg"],
    source  => 'puppet:///modules/jenkins/pubring.gpg',
  }

  file { "${home}/.config":
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File[$home],
  }

  file { "${home}/.m2":
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File[$home],
  }

  file { "${home}/.m2/settings.xml":
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => File["${home}/.m2"],
    source  => 'puppet:///modules/jenkins/settings.xml',
  }

}
