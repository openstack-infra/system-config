define jenkinsuser($ensure = present) {

  group { 'jenkins':
    ensure => 'present'
  }

  user { 'jenkins':
    ensure => 'present',
    comment => 'Jenkins User',
    home => '/home/jenkins',
    gid => 'jenkins',
    shell => '/bin/bash',
    groups => ['wheel','sudo'],
    membership => 'minimum',
  }

  file { 'jenkinshome':
    name => '/home/jenkins',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 644,
    ensure => 'directory',
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
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson",
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

  file { 'jenkinsbazaardir':
    name => '/home/jenkins/.bazaar',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => 'directory',
    require => File['jenkinshome'],
  }

  file { 'jenkinsbazaarwhoami':
    name => '/home/jenkins/.bazaar/bazaar.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['jenkinsbazaardir'],
    source => [
                "puppet:///modules/jenkins_slave/bazaar.conf",
              ],
  }

  file { 'jenkinsbazaarauth':
    name => '/home/jenkins/.bazaar/authentication.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['jenkinsbazaardir'],
    source => [
                "puppet:///modules/jenkins_slave/authentication.conf",
              ],
  }

  file { 'jenkinsknownhosts':
    name => '/home/jenkins/.ssh/known_hosts',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['jenkinssshdir'],
    source => [
                "puppet:///modules/jenkins_slave/known_hosts",
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
                "puppet:///modules/jenkins_slave/slave_private_key",
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
                "puppet:///modules/jenkins_slave/pubring.gpg",
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
                "puppet:///modules/jenkins_slave/slave_gpg_key",
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

  file { 'jenkinsconftarmacdir':
    name => '/home/jenkins/.config/tarmac',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => 'directory',
    require => File['jenkinsconfigdir'],
  }

  file { 'jenkinstarmacconf':
    name => '/home/jenkins/.config/tarmac/tarmac.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 644,
    ensure => 'present',
    require => File['jenkinsconftarmacdir'],
    source => [
                "puppet:///modules/jenkins_slave/tarmac.conf",
              ],
  }

  file { 'jenkinstarmaccredentials':
    name => '/home/jenkins/.config/tarmac/credentials',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['jenkinsconftarmacdir'],
    source => [
                "puppet:///modules/jenkins_slave/slave_tarmac_key",
              ],
  }

}
