class openstack_project::pypi_slave (
  pypi_password,
  pypi_username = 'openstackci'
) {
  include openstack_project::slave

  package { 'curl':
    ensure => present,
  }

  file { '/home/jenkins/.pypiactivate':
    owner => 'jenkins',
    group => 'jenkins',
    mode => 0600,
    ensure => 'present',
    content => template('openstack_project/pypiactivate.erb'),
    require => User['jenkins'],
  }
}
