class openstack_project::pypi_slave (
  pypi_password,
  pypi_username = 'openstackci'
) {
  include openstack_project::slave
  include pip

  package { 'pkginfo':
    ensure   => present,
    provider => 'pip',
    require  => Class['pip'],
  }

  file { '/home/jenkins/.pypicurl':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/pypicurl.erb'),
    require => File['/home/jenkins'],
  }
}
