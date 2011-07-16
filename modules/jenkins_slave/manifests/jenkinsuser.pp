class jenkinsuser {

  group { 'jenkins':
    ensure => 'present'
  }

  user { 'jenkins':
    ensure => 'present',
    comment => 'Jenkins User',
    home => $operatingsystem ? {
      Darwin => '/Users/jenkins',
      solaris => '/export/home/jenkins',
      default => '/home/jenkins',
    },
    gid => 'jenkins',
    shell => '/bin/bash',
    groups => ['wheel','sudo'],
    membership => 'minimum',
  }

  file { 'jenkinshome':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins',
      solaris => '/export/home/jenkins',
      default => '/home/jenkins',
    },
    owner => 'jenkins',
    group => 'jenkins',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'jenkinssshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins/.ssh',
      solaris => '/export/home/jenkins/.ssh',
      default => '/home/jenkins/.ssh',
    },
    owner => 'jenkins',
    group => 'jenkins',
    mode => 600,
    ensure => 'directory',
    require => File['jenkinshome'],
  }

  file { 'jenkinskeys':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins/.ssh/authorized_keys',
      solaris => '/export/home/jenkins/.ssh/authorized_keys',
      default => '/home/jenkins/.ssh/authorized_keys',
    },
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson",
    ensure => 'present',
    require => File['jenkinssshdir'],
  }

  file { 'jenkinsbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins/.bashrc',
      solaris => '/export/home/jenkins/.bashrc',
      default => '/home/jenkins/.bashrc',
    },
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'jenkinsbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins/.bash_logout',
      solaris => '/export/home/jenkins/.bash_logout',
      default => '/home/jenkins/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'jenkinsprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins/.profile',
      solaris => '/export/home/jenkins/.profile',
      default => '/home/jenkins/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'jenkinsbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins/.bazaar',
      solaris => '/export/home/jenkins/.bazaar',
      default => '/home/jenkins/.bazaar',
    },
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => 'directory',
    require => File['jenkinshome'],
  }


  file { 'jenkinsbazaarwhoami':
    name => $operatingsystem ? {
      Darwin => '/Users/jenkins/.bazaar/bazaar.conf',
      solaris => '/export/home/jenkins/.bazaar/bazaar.conf',
      default => '/home/jenkins/.bazaar/bazaar.conf',
    },
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    content => "[DEFAULT]\nemail = OpenStack Jenkins <jenkins@openstack.org>\n",
    ensure => 'present',
    require => File['jenkinsbazaardir'],
  }
}
  
