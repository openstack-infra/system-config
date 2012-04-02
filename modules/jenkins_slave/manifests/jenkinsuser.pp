define jenkinsuser($ensure = present, $ssh_key) {

  group { 'jenkins':
    ensure => 'present'
  }

  user { 'jenkins':
    ensure => 'present',
    comment => 'Jenkins User',
    home => '/home/jenkins',
    gid => 'jenkins',
    shell => '/bin/bash',
    membership => 'minimum',
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

  file { 'jenkinssshconfig':
    name => '/home/jenkins/.ssh/config',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['jenkinssshdir'],
    source => [
                "puppet:///modules/jenkins_slave/ssh_config",
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
                "puppet:///modules/jenkins_slave/glance_s3.conf",
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
                "puppet:///modules/jenkins_slave/glance_swift.conf",
              ],
  }


  file { '/home/jenkoins/slave_scripts':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 755,
    ensure => 'directory',
    require => File['jenkinshome']
  }


  file { '/home/jenkins/slave_scripts/baremetal-archive-logs.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/baremetal-archive-logs.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/baremetal-deploy.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/baremetal-deploy.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/baremetal-os-install.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/baremetal-os-install.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/build-bundle.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/build-bundle.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/build-venv.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/build-venv.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/copy-bundle.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/copy-bundle.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/copy-venv.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/copy-venv.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/create-ppa-package.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/create-ppa-package.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/create-tarball.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/create-tarball.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/gerrit-git-prep.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/gerrit-git-prep.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/lvm-kexec-reset.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/lvm-kexec-reset.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/propose_translations.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/propose_translations.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/run-cover.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/run-cover.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/run-docs.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/run-docs.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/run-tox.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/run-tox.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/update-pip-cache.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/update-pip-cache.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/wait_for_nova.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/wait_for_nova.sh,
              ],
  }


  file { '/home/jenkins/slave_scripts/wait_for_puppet.sh':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 640,
    ensure => 'present',
    require => File['/home/jenkins/slave_scripts'],
    source => [
                puppet:///modules/jenkins_slave/wait_for_puppet.sh,
              ],
  }

}
