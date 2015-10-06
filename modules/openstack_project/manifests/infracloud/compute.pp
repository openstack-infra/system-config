class openstack_project::infracloud::compute (
  $nova_rabbit_password,
  $neutron_rabbit_password,
  $neutron_admin_password,
  $controller_public_address,
  $controller_management_address,
) {
  class { '::infracloud::compute':
    nova_rabbit_password             => $nova_rabbit_password,
    neutron_rabbit_password          => $neutron_rabbit_password,
    neutron_admin_password           => $neutron_admin_password,
    controller_public_address        => $controller_public_address,
    controller_management_address    => $controller_management_address,
  }
}
