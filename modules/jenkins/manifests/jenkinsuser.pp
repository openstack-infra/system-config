class jenkins::jenkinsuser($ensure = present, $sudo = false, $ssh_key) {

  group { 'jenkins':
    ensure => 'present'
  }

  if ($sudo == true) {
    $groups = ['sudo', 'admin']
  } else {
    $groups = []
  }

  user { 'jenkins':
    ensure => 'present',
    comment => 'Jenkins User',
    home => '/home/jenkins',
    gid => 'jenkins',
    shell => '/bin/bash',
    membership => 'minimum',
    groups => $groups,
    require => Group['jenkins']
  }

  file { 'jenkinshome':
    name => '/home/jenkins',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 644,
    ensure => 'directory',
    require => User['jenkins']
  }
    
  file { 'jenkinspipdir':
    name => '/home/jenkins/.pip',
    owner => 'jenkins',
    group => 'jenkins',
    ensure => 'directory',
    require => File['jenkinshome'],
  }

  file { 'jenkinspipconf':
    name => '/home/jenkins/.pip/pip.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    source => "puppet:///modules/jenkins/pip.conf",
    require => File['jenkinspipdir'],
  }

  file { 'jenkinspydistutilscfg':
    name => '/home/jenkins/.pydistutils.cfg',
    ensure => 'absent',
    require => File['jenkinshome'],
  }

  file { 'jenkinsgitconfig':
    name => '/home/jenkins/.gitconfig',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    source => "puppet:///modules/jenkins/gitconfig",
    require => File['jenkinshome'],
  }
   
  file { 'jenkinssshdir':
    name => '/home/jenkins/.ssh',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 600,
    ensure => 'directory',
    require => File['jenkinshome'],
  }

  file { 'jenkinskeys':
    name => '/home/jenkins/.ssh/authorized_keys',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    content => "${ssh_key}",
    ensure => 'present',
    require => File['jenkinssshdir'],
  }

  file { 'jenkinsbashrc':
    name => '/home/jenkins/.bashrc',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'jenkinsbash_logout':
    name => '/home/jenkins/.bash_logout',
    source => "/etc/skel/.bash_logout",
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'jenkinsprofile':
    name => '/home/jenkins/.profile',
    source => "/etc/skel/.profile",
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'jenkinssshconfig':
    name => '/home/jenkins/.ssh/config',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['jenkinssshdir'],
    source => [
                "puppet:///modules/jenkins/ssh_config",
              ],
  }

  file { 'jenkinssshkey':
    name => '/home/jenkins/.ssh/id_rsa',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 600,
    ensure => 'present',
    require => File['jenkinssshdir'],
    source => [
                "puppet:///modules/jenkins/slave_private_key",
              ],
  }

  file { 'jenkinsgpgdir':
    name => '/home/jenkins/.gnupg',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 700,
    ensure => 'directory',
    require => File['jenkinshome'],
  }

  file { 'jenkinspubring':
    name => '/home/jenkins/.gnupg/pubring.gpg',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 600,
    ensure => 'present',
    require => File['jenkinsgpgdir'],
    source => [
                "puppet:///modules/jenkins/pubring.gpg",
              ],
  }

  file { 'jenkinssecring':
    name => '/home/jenkins/.gnupg/secring.gpg',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 600,
    ensure => 'present',
    require => File['jenkinsgpgdir'],
    source => [
                "puppet:///modules/jenkins/slave_gpg_key",
              ],
  }

  file { 'jenkinsconfigdir':
    name => '/home/jenkins/.config',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => 'directory',
    require => File['jenkinshome'],
  }

  file { 'jenkinsglanceconfigdir':
    name => '/home/jenkins/.config/glance',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 700,
    ensure => 'directory',
    require => File['jenkinsconfigdir'],
  }

  file { 'glances3conf':
    name => '/home/jenkins/.config/glance/s3.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 400,
    ensure => 'present',
    require => File['jenkinsglanceconfigdir'],
    source => [
                "puppet:///modules/jenkins/glance_s3.conf",
              ],
  }

  file { 'glanceswiftconf':
    name => '/home/jenkins/.config/glance/swift.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 400,
    ensure => 'present',
    require => File['jenkinsglanceconfigdir'],
    source => [
                "puppet:///modules/jenkins/glance_swift.conf",
              ],
  }



}
