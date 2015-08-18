class openstack_project::infracloud::compute(
  $nova_mysql_password,
  $nova_rabbit_password,
  $controller_address,
) {
  # Repos
  include ::apt

  class { 'openstack_extras::repo::debian::ubuntu':
    release         => 'kilo',
    package_require => true,
  }

  # Nova
  class { '::nova':
    rabbit_userid       => 'nova',
    rabbit_password     => $nova_rabbit_password,
    rabbit_host         => $controller_address,
    glance_api_servers  => "${controller_address}:9292",
  }

  class { '::nova::compute': }
}
