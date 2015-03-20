# Slave used for automatically proposing changes to Gerrit,
# Transifex and other tools.
#
# == Class: openstack_project::translation_slave
#
class openstack_project::proposal_slave (
  $jenkins_ssh_public_key,
  $proposal_ssh_public_key,
  $proposal_ssh_private_key,
  $transifex_password = '',
  $transifex_username = 'openstackci',
) {

  class { 'openstack_project::slave':
    ssh_key => $jenkins_ssh_public_key,
  }

  package { ['transifex-client', 'Babel']:
    ensure   => latest,
    provider => pip,
    require  => Class['pip'],
  }

  file { '/home/jenkins/.transifexrc':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/transifexrc.erb'),
    require => User['jenkins'],
  }

  file { '/opt/zanata':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode     => '0644',
    require  => User['jenkins'],
  }

  exec { 'get_zanata_client_dist_tarball':
    command => 'wget https://search.maven.org/remotecontent?filepath=org/zanata/zanata-cli/3.4.2/zanata-cli-3.4.2-dist.tar.gz -O /opt/zanata/zanata-cli-3.4.2-dist.tar.gz',
    path    => '/bin:/usr/bin',
    creates => '/opt/zanata/zanata-cli-3.4.2-dist.tar.gz',
    require => File['/opt/zanata'],
  }

  file { '/opt/zanata/zanata-cli-3.4.2-dist.tar.gz':
    ensure => present,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0644',
    require => Exec['get_zanata_client_dist_tarball'],
  }

  exec { 'unpack_zanata_client_dist_tarball':
    command => 'tar zxf zanata-cli-3.4.2-dist.tar.gz',
    path    => '/bin:/usr/bin',
    user    => 'jenkins',
    cwd     => '/opt/zanata',
    creates => '/opt/zanata/zanata-cli-3.4.2/bin/zanata-cli',
    require => Exec['get_zanata_client_dist_tarball'],
  }

  file { '/opt/zanata/zanata-cli-3.4.2/bin/zanata-cli':
    ensure => present,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0755',
    require => Exec['unpack_zanata_client_dist_tarball'],
  }

  file { '/usr/local/bin/zanata-cli':
    ensure  => link,
    target  => '/opt/zanata/zanata-cli-3.4.2/bin/zanata-cli',
    require => File['/opt/zanata/zanata-cli-3.4.2/bin/zanata-cli'],
  }

  file { '/home/jenkins/.ssh/id_rsa':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['/home/jenkins/.ssh'],
    content => $proposal_ssh_private_key,
  }

  file { '/home/jenkins/.ssh/id_rsa.pub':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['/home/jenkins/.ssh'],
    content => $proposal_ssh_public_key,
  }
}
