class openstack_project::infracloud::compute (
  $nova_rabbit_password,
  $neutron_rabbit_password,
  $neutron_admin_password,
  $ssl_key_file_contents,
  $ssl_cert_file_contents,
  $br_name,
  $controller_public_address,
  $openstack_release = 'mitaka',
) {
  include ::openstack_project::infracloud::base

  class { '::infracloud::compute':
    nova_rabbit_password          => $nova_rabbit_password,
    neutron_rabbit_password       => $neutron_rabbit_password,
    neutron_admin_password        => $neutron_admin_password,
    ssl_key_file_contents         => $ssl_key_file_contents,
    ssl_cert_file_contents        => $ssl_cert_file_contents,
    br_name                       => $br_name,
    controller_public_address     => $controller_public_address,
    openstack_release             => $openstack_release,
  }
}
