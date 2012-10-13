class jenkins::jenkinsuser(
  $ssh_key,
  $ensure = present,
  $sudo   = false
) {

  group { 'jenkins':
    ensure => present
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
    require    => Group['jenkins'],
  }

  file { 'jenkinshome':
    ensure  => directory,
    name    => '/home/jenkins',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => User['jenkins'],
  }

  file { 'jenkinspipdir':
    ensure  => directory,
    name    => '/home/jenkins/.pip',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['jenkinshome'],
  }

  file { 'jenkinspipconf':
    ensure  => present,
    name    => '/home/jenkins/.pip/pip.conf',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => 'puppet:///modules/jenkins/pip.conf',
    require => File['jenkinspipdir'],
  }

  file { 'jenkinspydistutilscfg':
    ensure  => absent,
    name    => '/home/jenkins/.pydistutils.cfg',
    require => File['jenkinshome'],
  }

  file { 'jenkinsgitconfig':
    ensure  => present,
    name    => '/home/jenkins/.gitconfig',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => 'puppet:///modules/jenkins/gitconfig',
    require => File['jenkinshome'],
  }

  file { 'jenkinssshdir':
    ensure  => directory,
    name    => '/home/jenkins/.ssh',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['jenkinshome'],
  }

  file { 'jenkinskeys':
    ensure  => present,
    name    => '/home/jenkins/.ssh/authorized_keys',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => "${ssh_key}",
    require => File['jenkinssshdir'],
  }

  file { 'jenkinsbashrc':
    ensure  => present,
    name    => '/home/jenkins/.bashrc',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => '/etc/skel/.bashrc',
    replace => false,
  }

  file { 'jenkinsbash_logout':
    ensure  => present,
    name    => '/home/jenkins/.bash_logout',
    source  => '/etc/skel/.bash_logout',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    replace => false,
  }

  file { 'jenkinsprofile':
    ensure  => present,
    name    => '/home/jenkins/.profile',
    source  => '/etc/skel/.profile',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    replace => false,
  }

  file { 'jenkinssshconfig':
    ensure  => present,
    name    => '/home/jenkins/.ssh/config',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    require => File['jenkinssshdir'],
    source  => [
                'puppet:///modules/jenkins/ssh_config',
              ],
  }

  file { 'jenkinsgpgdir':
    ensure  => directory,
    name    => '/home/jenkins/.gnupg',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File['jenkinshome'],
  }

  file { 'jenkinspubring':
    ensure  => present,
    name    => '/home/jenkins/.gnupg/pubring.gpg',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['jenkinsgpgdir'],
    source  => [
                'puppet:///modules/jenkins/pubring.gpg',
              ],
  }

  file { 'jenkinsconfigdir':
    ensure  => directory,
    name    => '/home/jenkins/.config',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['jenkinshome'],
  }
}
