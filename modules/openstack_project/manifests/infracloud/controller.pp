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
  $neutron_ssl_key,
  $neutron_ssl_cert,
  $glance_ssl_key,
  $glance_ssl_cert,
  $nova_ssl_key,
  $nova_ssl_cert,
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
  class { '::keystone::wsgi::apache':
    ssl_key   => "/etc/keystone/ssl/private/${::fqdn}.pem",
    ssl_cert  => "/etc/keystone/ssl/certs/${::fqdn}.pem",
    ssl_chain => "/etc/keystone/ssl/certs/${::fqdn}_ca.pem",
  }
  openstack_project::infracloud::ssl { 'keystone':
    key_content   => $keystone_ssl_key,
    cert_content  => $keystone_ssl_cert,
    chain_content => $keystone_ssl_chain,
    before        => Service['httpd'],
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
    cert_file           => "/etc/glance/ssl/certs/${::fqdn}.pem",
    key_file            => "/etc/glance/ssl/private/${::fqdn}.pem",
  }
  openstack_project::infracloud::ssl { 'glance':
    key_content  => $glance_ssl_key,
    cert_content => $glance_ssl_cert,
    before       => Service['glance-api'],
  }
  class { '::glance::registry':
    database_connection => "mysql://glance:${glance_mysql_password}@127.0.0.1/glance",
    keystone_password   => $glance_admin_password,
    auth_uri            => "https://${::fqdn}:5000",
    identity_uri        => "https://${::fqdn}:35357",
  }
  class { '::glance::keystone::auth':
    password   => $glance_admin_password,
    public_url => "https://${::fqdn}:9292",
    admin_url  => "https://${::fqdn}:9292",
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
    use_ssl         => true,
    cert_file       => "/etc/neutron/ssl/certs/${::fqdn}.pem",
    key_file        => "/etc/neutron/ssl/private/${::fqdn}.pem",
  }
  openstack_project::infracloud::ssl { 'neutron':
    key_content  => $neutron_ssl_key,
    cert_content => $neutron_ssl_cert,
    before       => Service['neutron-server'],
  }
  class { '::neutron::keystone::auth':
    password   => $neutron_admin_password,
    public_url => "https://${::fqdn}:9696/",
    admin_url  => "https://${::fqdn}:9696/",
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
    public_url => "https://${::fqdn}:8774/v2/%(tenant_id)s",
    admin_url  => "https://${::fqdn}:8774/v2/%(tenant_id)s",
  }

  class { '::nova':
    database_connection => "mysql://nova:${nova_mysql_password}@127.0.0.1/nova?charset=utf8",
    rabbit_userid       => 'nova',
    rabbit_password     => $nova_rabbit_password,
    glance_api_servers  => 'localhost:9292',
    use_ssl             => true,
    cert_file           => "/etc/nova/ssl/certs/${::fqdn}.pem",
    key_file            => "/etc/nova/ssl/private/${::fqdn}.pem",
  }
  openstack_project::infracloud::ssl { 'nova':
    key_content  => $nova_ssl_key,
    cert_content => $nova_ssl_cert,
    before       => Service['nova-api'],
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
