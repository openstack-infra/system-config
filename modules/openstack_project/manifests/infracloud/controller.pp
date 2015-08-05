# class: OpenStack Infra Cloud
class openstack_project::infracloud::controller(
  $neutron_rabbit_password,
  $nova_rabbit_password,
  $keystone_mysql_password,
  $glance_mysql_password,
  $neutron_mysql_password,
  $nova_mysql_password,
  $glance_admin_password,
  $keystone_admin_password,
  $neutron_admin_password,
  $nova_admin_password,
  $keystone_admin_token,
  $ssl_chain_file_contents,
  $keystone_ssl_key_file_contents,
  $keystone_ssl_cert_file_contents,
  $neutron_ssl_key_file_contents,
  $neutron_ssl_cert_file_contents,
  $glance_ssl_key_file_contents,
  $glance_ssl_cert_file_contents,
  $nova_ssl_key_file_contents,
  $nova_ssl_cert_file_contents,
  $controller_management_address,
  $controller_public_address = $::fqdn,
) {

  $keystone_auth_uri = "https://${controller_public_address}:5000",
  $keystone_admin_uri = "https://${controller_public_address}:35357",

  ### Certificate Chain ###

  # This chain file needs to sign every other cert
  $ssl_chain_path = "/etc/ssl/certs/${controller_public_address}-ca.pem"
  file { $ssl_chain_path:
    ensure  => present,
    content => $ssl_chain_file_contents,
    mode    => '0644',
  }

  ### Networking ###

  include ::openstack_project::infracloud::veth

  ### Repos ###

  include ::apt

  class { 'openstack_extras::repo::debian::ubuntu':
    release         => 'kilo',
    package_require => true,
  }

  ### Database ###

  class { '::mysql::server': }

  ### Messaging ###

  class { '::rabbitmq':
    delete_guest_user     => true,
    environment_variables => {
      'RABBITMQ_NODE_IP_ADDRESS' => $controller_management_address,
    }
  }

  ### Keystone ###

  class { '::keystone::db::mysql':
    password => $keystone_mysql_password,
  }

  # keystone.conf
  class { '::keystone':
    database_connection  => "mysql://keystone:${keystone_mysql_password}@127.0.0.1/keystone",
    catalog_type         => 'sql',
    admin_token          => $keystone_admin_token,
    service_name         => 'httpd',
    enable_ssl           => true,
    admin_bind_host      => $controller_public_address,
  }

  # keystone admin user, projects
  class { '::keystone::roles::admin':
    email    => 'postmaster@no.test',
    password => $keystone_admin_password,
  }

  # keystone auth endpoints
  class { '::keystone::endpoint':
    public_url => $keystone_auth_uri,
    admin_url  => $keystone_admin_uri,
  }

  # apache server
  include ::apache

  $keystone_ssl_key_path = "/etc/ssl/private/${controller_public_address}-keystone.pem"
  $keystone_ssl_cert_path = "/etc/ssl/certs/${controller_public_address}-keystone.pem"

  # keystone vhost
  class { '::keystone::wsgi::apache':
    ssl_key   => $keystone_ssl_key_path,
    ssl_cert  => $keystone_ssl_chain_path,
    ssl_chain => $ssl_chain_path,
  }

  openstack_project::infracloud::ssl { 'keystone':
    key_content  => $keystone_ssl_key_file_contents,
    cert_content => $keystone_ssl_cert_file_contents,
    key_path     => $keystone_ssl_key_path,
    cert_path    => $keystone_ssl_chain_path,
  }

  ### Glance ###

  $glance_database_connection = "mysql://glance:${glance_mysql_password}@127.0.0.1/glance"

  class { '::glance::db::mysql':
    password => $glance_mysql_password,
  }

  # glance-api.conf
  class { '::glance::api':
    bind_host           => $controller_public_address,
    database_connection => $glance_database_connection,
    keystone_password   => $glance_admin_password,
    auth_uri            => $keystone_auth_uri,
    identity_uri        => $keystone_admin_uri,
    cert_file           => "/etc/glance/ssl/certs/${controller_public_address}.pem",
    key_file            => "/etc/glance/ssl/private/${controller_public_address}.pem",
  }

  openstack_project::infracloud::ssl { 'glance':
    key_content  => $glance_ssl_key_file_contents,
    cert_content => $glance_ssl_cert_file_contents,
    before       => Service['glance-api'],
  }

  # glance-registry.conf
  class { '::glance::registry':
    database_connection => $glance_database_connection,
    keystone_password   => $glance_admin_password,
    auth_uri            => $keystone_auth_uri,
    identity_uri        => $keystone_admin_uri,
  }

  # keystone user, role, service, endpoints for glance service
  class { '::glance::keystone::auth':
    password   => $glance_admin_password,
    public_url => "https://${controller_public_address}:9292",
    admin_url  => "https://${controller_public_address}:9292",
  }

  ### Neutron server ###
  sysctl::value { 'net.ipv4.conf.default.rp_filter':
    value => 0
  }
  sysctl::value { 'net.ipv4.conf.all.rp_filter':
    value => 0
  }

  class { '::neutron::db::mysql':
    password => $neutron_mysql_password,
  }

  openstack_project::infracloud::rabbitmq_user { 'neutron':
    password => $neutron_rabbit_password,
  }

  # neutron.conf
  class { '::neutron':
    core_plugin     => 'ml2',
    enabled         => true,
    rabbit_user     => 'neutron',
    rabbit_password => $neutron_rabbit_password,
    rabbit_host     => $controller_management_address,
    use_ssl         => true,
    cert_file       => "/etc/neutron/ssl/certs/${controller_public_address}.pem",
    key_file        => "/etc/neutron/ssl/private/${controller_public_address}.pem",
  }

  openstack_project::infracloud::ssl { 'neutron':
    key_content  => $neutron_ssl_key_file_contents,
    cert_content => $neutron_ssl_cert_file_contents,
    before       => Service['neutron-server'],
  }

  # keystone user, role, service, endpoints for neutron service
  class { '::neutron::keystone::auth':
    password   => $neutron_admin_password,
    public_url => "https://${controller_public_address}:9696/",
    admin_url  => "https://${controller_public_address}:9696/",
  }

  # neutron-server service and related neutron.conf and api-paste.conf params
  class { '::neutron::server':
    auth_password       => $neutron_admin_password,
    database_connection => "mysql://neutron:${neutron_mysql_password}@127.0.0.1/neutron?charset=utf8",
    sync_db             => true,
    auth_uri            => $keystone_auth_uri,
    identity_uri        => $keystone_admin_uri,
  }

  # neutron client package
  class { '::neutron::client': }

  # neutron.conf nova credentials
  class { '::neutron::server::notifications':
    nova_url               => "https://${controller_public_address}:8774/v2",
    nova_admin_auth_url    => "${keystone_admin_uri}/v2.0",
    nova_admin_username    => 'nova',
    nova_admin_password    => $nova_admin_password,
    nova_admin_tenant_name => 'services',
  }

  # ML2
  class { '::neutron::plugins::ml2':
    type_drivers          => ['flat', 'vlan'],
    tenant_network_types  => [],
    mechanism_drivers     => ['linuxbridge'],
    flat_networks         => ['provider'],
    network_vlan_ranges   => ['provider'],
    enable_security_group => true,
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

  # DHCP
  class { '::neutron::agents::dhcp':
    interface_driver       => 'neutron.agent.linux.interface.BridgeInterfaceDriver',
    dhcp_delete_namespaces => true,
  }

  ### Nova ###

  class { '::nova::db::mysql':
    password => $nova_mysql_password,
    host     => '127.0.0.1',
  }

  openstack_project::infracloud::rabbitmq_user { 'nova':
    password => $nova_rabbit_password,
  }

  # nova.conf - general
  class { '::nova':
    database_connection => "mysql://nova:${nova_mysql_password}@127.0.0.1/nova?charset=utf8",
    rabbit_userid       => 'nova',
    rabbit_password     => $nova_rabbit_password,
    rabbit_host         => $controller_management_address,
    glance_api_servers  => "https://${controller_public_address}:9292",
    use_ssl             => true,
    cert_file           => "/etc/nova/ssl/certs/${controller_public_address}.pem",
    key_file            => "/etc/nova/ssl/private/${controller_public_address}.pem",
  }
  openstack_project::infracloud::ssl { 'nova':
    key_content  => $nova_ssl_key_file_contents,
    cert_content => $nova_ssl_cert_file_contents,
    before       => Service['nova-api'],
    require      => Class['::nova'],
  }

  # keystone user, role, service, endpoints for nova service
  class { '::nova::keystone::auth':
    password   => $nova_admin_password,
    public_url => "https://${controller_public_address}:8774/v2/%(tenant_id)s",
    admin_url  => "https://${controller_public_address}:8774/v2/%(tenant_id)s",
  }

  # nova.conf neutron credentials
  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_admin_password,
    neutron_url            => "https://${controller_public_address}:9696",
  }

  # api service and endpoint-related params in nova.conf
  class { 'nova::api':
    enabled        => true,
    enabled_apis   => 'osapi_compute,metadata',
    admin_password => $nova_admin_password,
    auth_uri       => $keystone_auth_uri,
    identity_uri   => $keystone_admin_uri,
  }

  # conductor service
  class { 'nova::conductor': }

  # scheduler service
  class { 'nova::scheduler': }
}
