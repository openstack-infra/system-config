# == Class: openstack_project::translation_slave
#
class openstack_project::translation_slave (
  $transifex_password = '',
  $transifex_username = 'openstackci',
) {

  include openstack_project::slave

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
}
