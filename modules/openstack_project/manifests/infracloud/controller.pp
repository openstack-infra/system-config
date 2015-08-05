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
  $keystone_ssl_key,
  $keystone_ssl_cert,
  $keystone_ssl_chain,
  $keystone_ssl_key_path = "/etc/keystone/ssl/private/${::fqdn}-key.pem",
  $keystone_ssl_cert_path = "/etc/keystone/ssl/certs/${::fqdn}.pem",
  $keystone_ssl_chain_path = "/etc/keystone/ssl/certs/ca-intermediate.pem",
  $keystone_auth_uri = "https://${::fqdn}:5000",
  $keystone_admin_uri = "https://${::fqdn}:35357",
) {

  # Repos
  include ::apt

  class { 'openstack_extras::repo::debian::ubuntu':
    release         => 'kilo',
    package_require => true,
  }

  # Database
  class { '::mysql::server': }

  # Messaging
  class { '::rabbitmq':
    delete_guest_user => true,
  }

  # Keystone
  class { '::keystone::db::mysql':
    password => $baremetal_mysql_password,
  }
  class { '::keystone':
    database_connection  => "mysql://keystone:${baremetal_mysql_password}@127.0.0.1/keystone",
    catalog_type         => 'sql',
    admin_token          => $keystone_admin_token,
    service_name        => 'httpd',
    enable_ssl           => true,
    admin_bind_host      => $::fqdn,
  }
  class { '::keystone::roles::admin':
    email    => 'postmaster@no.test',
    password => $keystone_service_password,
  }
  class { '::keystone::endpoint':
    public_url => $keystone_auth_uri,
    admin_url  => $keystone_admin_uri,
  }

  include ::apache
  $key_path  = "/etc/keystone/ssl/private/${::fqdn}-key.pem"
  $cert_path = "/etc/keystone/ssl/certs/${::fqdn}.pem"

  file { $key_path:
    ensure  => present,
    content => $keystone_ssl_key,
    mode    => '0600',
  }
  file { $cert_path:
    ensure  => present,
    content => $keystone_ssl_cert,
    mode    => '0644',
  }
  file { $keystone_ssl_chain_path:
    ensure  => present,
    content => $keystone_ssl_chain,
    mode    => '0644',
  }
  class { '::keystone::wsgi::apache':
    ssl_key   => $keystone_ssl_key_path,
    ssl_cert  => $keystone_ssl_cert_path,
    ssl_chain => $keystone_ssl_chain_path,
    require   => File[$key_path, $cert_path],
  }

  # Glance
  class { '::glance::db::mysql':
    password => $glance_mysql_password,
  }
  class { '::glance::api':
    database_connection => "mysql://glance:${glance_mysql_password}@127.0.0.1/glance",
    keystone_password   => $glance_admin_password,
    auth_uri            => "https://${::fqdn}:5000",
    identity_uri        => "https://${::fqdn}:35357",
  }
  class { '::glance::registry':
    database_connection => "mysql://glance:${glance_mysql_password}@127.0.0.1/glance",
    keystone_password   => $glance_admin_password,
    auth_uri            => "https://${::fqdn}:5000",
    identity_uri        => "https://${::fqdn}:35357",
  }
  class { '::glance::keystone::auth':
    password   => $glance_admin_password,
    public_url => "http://${::fqdn}:9292",
    admin_url  => "http://${::fqdn}:9292",
  }

  # Neutron server
  sysctl::value { 'net.ipv4.conf.default.rp_filter':
    value => 0
  }
  sysctl::value { 'net.ipv4.conf.all.rp_filter':
    value => 0
  }
  class { '::neutron::db::mysql':
    password => $neutron_mysql_password,
  }
  rabbitmq_user { 'neutron':
    admin    => false,
    password => $neutron_rabbit_password,
  }
  rabbitmq_user_permissions { 'neutron@/':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }
  class { '::neutron':
    core_plugin     => 'ml2',
    enabled         => true,
    rabbit_user     => 'neutron',
    rabbit_password => $neutron_rabbit_password,
  }
  class { '::neutron::keystone::auth':
    password   => $neutron_admin_password,
    public_url => "http://${::fqdn}:9696/",
    admin_url  => "http://${::fqdn}:9696/",
  }
  class { '::neutron::server':
    auth_password       => $neutron_admin_password,
    database_connection => "mysql://neutron:${neutron_mysql_password}@127.0.0.1/neutron?charset=utf8",
    sync_db             => true,
    auth_uri            => "https://${::fqdn}:5000",
    identity_uri        => "https://${::fqdn}:35357",
  }
  class { '::neutron::plugins::ml2':
    type_drivers          => ['flat'],
    tenant_network_types  => [],
    mechanism_drivers     => ['linuxbridge'],
    flat_networks         => ['provider'],
    network_vlan_ranges   => ['provider'],
    enable_security_group => false,
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
  class { '::neutron::agents::dhcp':
    interface_driver       => 'neutron.agent.linux.interface.BridgeInterfaceDriver',
    dhcp_delete_namespaces => true,
  }
  class { '::neutron::client': }

  # Nova
  rabbitmq_user { 'nova':
    admin    => false,
    password => $nova_rabbit_password,
  }
  rabbitmq_user_permissions { 'nova@/':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }
  class { '::nova::db::mysql':
    password => $nova_mysql_password,
    host     => '127.0.0.1',
  }
  class { '::nova::keystone::auth':
    password   => $nova_admin_password,
    public_url => "http://${::fqdn}:8774/v2/%(tenant_id)s",
    admin_url  => "http://${::fqdn}:8774/v2/%(tenant_id)s",
  }

  class { '::nova':
    database_connection => "mysql://nova:${nova_mysql_password}@127.0.0.1/nova?charset=utf8",
    rabbit_userid       => 'nova',
    rabbit_password     => $nova_rabbit_password,
    glance_api_servers  => 'localhost:9292',
  }
  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_admin_password,
  }

  class { 'nova::api':
    enabled        => true,
    enabled_apis   => 'osapi_compute,metadata',
    admin_password => $nova_admin_password,
    auth_uri       => "https://${::fqdn}:5000",
    identity_uri   => "https://${::fqdn}:35357",
  }
  class { 'nova::conductor':
    enabled => true,
  }
  class { 'nova::scheduler':
    enabled => true,
  }
}
