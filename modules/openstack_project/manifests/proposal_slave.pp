# Slave used for automatically proposing changes to Gerrit,
# Transifex and other tools.
#
# == Class: openstack_project::translation_slave
#
class openstack_project::proposal_slave (
  $jenkins_ssh_public_key,
  $jenkins_ssh_private_key,
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

  file { '/home/jenkins/.ssh/id_rsa':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['/home/jenkins/.ssh'],
    content => $jenkins_ssh_private_key,
  }
}
