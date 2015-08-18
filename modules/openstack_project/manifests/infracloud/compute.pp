class openstack_project::infracloud::compute(
  $nova_mysql_password,
  $nova_rabbit_password,
  $neutron_rabbit_password,
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

  class { '::nova::compute':
    enabled => true,
  }

  # Neutron
  class { '::neutron':
    rabbit_user     => 'neutron',
    rabbit_password => $neutron_rabbit_password,
    rabbit_host     => $controller_address,
  }

  class { '::neutron::agents::ml2::linuxbridge':
    physical_interface_mappings => ['provider:eth1'],
  }

  # Fix for https://bugs.launchpad.net/ubuntu/+source/neutron/+bug/1453188
  file { '/usr/bin/neutron-plugin-linuxbridge-agent':
    ensure => link,
    target => '/usr/bin/neutron-linuxbridge-agent',
    before => Package['neutron-plugin-linuxbridge-agent'],
  }
}
