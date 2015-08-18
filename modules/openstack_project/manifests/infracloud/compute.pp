class openstack_project::infracloud::compute(
  $nova_mysql_password,
  $nova_rabbit_password,
  $neutron_rabbit_password,
  $neutron_admin_password,
  $controller_address,
  $controller_management_address,
) {

  # Networking
  include ::openstack_project::infracloud::veth

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
    rabbit_host         => $controller_management_address,
    glance_api_servers  => "https://${controller_address}:9292",
  }

  class { '::nova::compute':
    enabled => true,
  }

  class { '::nova::network::neutron':
    neutron_url            => "https://${controller_address}:9696",
    neutron_admin_auth_url => "https://${controller_address}:35357/v2.0",
    neutron_admin_password => $neutron_admin_password,
  }

  # Neutron
  class { '::neutron':
    rabbit_user     => 'neutron',
    rabbit_password => $neutron_rabbit_password,
    rabbit_host     => $controller_management_address,
  }

  class { '::neutron::agents::ml2::linuxbridge':
    physical_interface_mappings => ['provider:veth2'],
  }

  # Fix for https://bugs.launchpad.net/ubuntu/+source/neutron/+bug/1453188
  file { '/usr/bin/neutron-plugin-linuxbridge-agent':
    ensure => link,
    target => '/usr/bin/neutron-linuxbridge-agent',
    before => Package['neutron-plugin-linuxbridge-agent'],
  }
}
