class openstack_project::translation_slave (
  transifex_username = 'openstackci',
  transifex_password
) {

  include openstack_project::slave

  package { ['transifex-client', 'Babel']:
    ensure => latest,
    provider => pip,
    require => Class[pip]
  }

  file { '/home/jenkins/.transifexrc':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 0600,
    ensure => 'present',
    content => template('openstack_project/transifexrc.erb'),
    require => User['jenkins'],
  }

}
