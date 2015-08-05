#
# Top-level variables
#
# There are currently no top-level variables, but we need an empty space before
# the node definition so the apply test parses correctly.
#

# Node-OS: trusty
node 'controller01.hpuswest.ic.openstack.org' {
  $group = 'infracloud-controller'
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [5000,5672,8774,9292,9696,35357], # keystone,rabbit,nova,glance,neutron,keystone
    sysadmins                 => hiera('sysadmins', []),
  }
  class { '::openstack_project::infracloud::controller':
    neutron_rabbit_password          => hiera('neutron_rabbit_password', 'XXX'),
    nova_rabbit_password             => hiera('nova_rabbit_password', 'XXX'),
    keystone_mysql_password          => hiera('keystone_mysql_password', 'XXX'),
    glance_mysql_password            => hiera('glance_mysql_password', 'XXX'),
    neutron_mysql_password           => hiera('neutron_mysql_password', 'XXX'),
    nova_mysql_password              => hiera('nova_mysql_password', 'XXX'),
    keystone_admin_password          => hiera('keystone_admin_password', 'XXX'),
    glance_admin_password            => hiera('glance_admin_password', 'XXX'),
    neutron_admin_password           => hiera('neutron_admin_password', 'XXX'),
    nova_admin_password              => hiera('nova_admin_password', 'XXX'),
    keystone_admin_token             => hiera('keystone_admin_token', 'admin_token_xxx1234'),
    ssl_chain_file_contents          => hiera('ssl_chain_file_contents', 'XXX'),
    keystone_ssl_key_file_contents   => hiera('keystone_ssl_key_file_contents', 'XXX'),
    keystone_ssl_cert_file_contents  => hiera('keystone_ssl_cert_file_contents', 'XXX'),
    glance_ssl_key_file_contents     => hiera('glance_ssl_key_file_contents', 'XXX'),
    glance_ssl_cert_file_contents    => hiera('glance_ssl_cert_file_contents', 'XXX'),
    neutron_ssl_key_file_contents    => hiera('neutron_ssl_key_file_contents', 'XXX'),
    neutron_ssl_cert_file_contents   => hiera('neutron_ssl_cert_file_contents', 'XXX'),
    nova_ssl_key_file_contents       => hiera('nova_ssl_key_file_contents', 'XXX'),
    nova_ssl_cert_file_contents      => hiera('nova_ssl_cert_file_contents', 'XXX'),
    controller_public_address        => 'controller01.hpuswest.ic.openstack.org',
    controller_management_address    => '10.10.16.154',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
