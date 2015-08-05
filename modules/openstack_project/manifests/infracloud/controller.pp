class openstack_project::infracloud::controller(
  $baremetal_rabbit_password,
  $baremetal_mysql_password,
  $glance_mysql_password,
  $glance_admin_password,
  $keystone_service_password,
  $neutron_rabbit_password,
  $neutron_mysql_password,
  $neutron_admin_password,
  $nova_rabbit_password,
  $nova_mysql_password,
  $nova_admin_password,
  $keystone_admin_token,
  $keystone_auth_uri = "http://${::fqdn}:5000/v2.0",
  $keystone_admin_uri = "http://${::fqdn}:35357/v2.0",
) {

  include ::apt

  class { 'openstack_extras::repo::debian::ubuntu':
    release         => 'kilo',
    package_require => true,
  }

  class { '::mysql::server': }
  class { '::rabbitmq':
    delete_guest_user => true,
  }
  class { '::keystone::db::mysql':
    password => $baremetal_mysql_password,
  }
  class { '::keystone':
    database_connection => "mysql://keystone:${baremetal_mysql_password}@127.0.0.1/keystone",
    catalog_type        => 'sql',
    admin_token         => $keystone_admin_token,
    service_name        => 'httpd',
  }
  class { '::keystone::roles::admin':
    email    => 'postmaster@no.test',
    password => $keystone_service_password,
  }
  keystone::resource::service_identity { 'keystone':
    password            => $keystone_service_password,
    service_type        => 'identity',
    service_description => 'OpenStack Identity Service',
    public_url          => $keystone_auth_uri,
    admin_url           => $keystone_admin_uri,
  }

  include ::apache
  class { '::keystone::wsgi::apache':
    ssl => false,
  }

  class { '::glance::db::mysql':
    password => $glance_mysql_password,
  }
  class { '::glance::api':
    database_connection => "mysql://glance:${glance_mysql_password}@127.0.0.1/glance",
    keystone_password => $glance_admin_password,
  }
  class { '::glance::registry':
    database_connection => "mysql://glance:${glance_mysql_password}@127.0.0.1/glance",
    keystone_password => $glance_admin_password,
  }
  keystone::resource::service_identity { 'glance':
    password => $glance_admin_password,
    service_type => 'image',
    service_description => 'OpenStack Image Service',
    public_url => "http://${::fqdn}:9292/",
    admin_url => "http://${::fqdn}:9292/",
  }
  rabbitmq_user { 'neutron':
    admin => false,
    password => $neutron_rabbit_password,
  }
  rabbitmq_user_permissions { 'neutron@/':
    configure_permission => '.*',
    read_permission => '.*',
    write_permission => '.*',
  }
  class { '::neutron::db::mysql':
    password => $neutron_mysql_password,
  }
  class { '::neutron':
    core_plugin => 'ml2',
    enabled => true,
    rabbit_user => 'neutron',
    rabbit_password => $neutron_rabbit_password,
  }
  keystone::resource::service_identity { 'neutron':
    password => $neutron_admin_password,
    service_type => 'network',
    service_description => 'OpenStack Network Service',
    public_url => "http://${::fqdn}:9696/",
    admin_url => "http://${::fqdn}:9696/",
  }
  class { '::neutron::server':
    auth_password => $neutron_admin_password,
    #auth_uri => $keystone_auth_uri,
    #identity_uri => $keystone_admin_uri,
    database_connection => "mysql://neutron:${neutron_mysql_password}@127.0.0.1/neutron?charset=utf8",
  }
  class { '::neutron::plugins::ml2':
    type_drivers => ['flat'],
    tenant_network_types => ['flat'],
    mechanism_drivers => ['openvswitch'],
    flat_networks => ['physnet1'],
    network_vlan_ranges => ['physnet1'],
    enable_security_group => false,
  }
  class { '::neutron::agents::ml2::ovs':
    bridge_mappings => ['physnet1:br-eth2'],
  }
  class { '::neutron::agents::dhcp': }
  class { '::neutron::client': }

  rabbitmq_user { 'nova':
    admin => false,
    password => $nova_rabbit_password,
  }
  rabbitmq_user_permissions { 'nova@/':
    configure_permission => '.*',
    read_permission => '.*',
    write_permission => '.*',
  }
  class { '::nova::db::mysql':
    password => $nova_mysql_password,
    host => '127.0.0.1',
  }
  keystone::resource::service_identity { 'nova':
    password => $nova_admin_password,
    service_type => 'compute',
    service_description => 'OpenStack Compute Service',
    public_url => "http://${::fqdn}:8774/v2",
    admin_url => "http://${::fqdn}:8774/v2",
  }

  class { '::nova':
    database_connection => "mysql://nova:${nova_mysql_password}@127.0.0.1/nova?charset=utf8",
    rabbit_userid => 'nova',
    rabbit_password => $nova_rabbit_password,
    glance_api_servers => 'localhost:9292',
  }
  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_admin_password,
  }

  class { 'nova::compute':
    enabled => true,
  }
  class { 'nova::api':
    enabled => true,
    enabled_apis => 'osapi_compute,metadata',
    admin_password => $nova_admin_password,
  }
  class { 'nova::conductor':
    enabled => true,
  }
  class { 'nova::scheduler':
    enabled => true,
  }
  class { 'nova::compute::ironic':
    admin_passwd => $nova_admin_password,
  }
}
