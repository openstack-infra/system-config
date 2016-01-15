class openstack_project::infracloud::compute (
  $nova_rabbit_password,
  $neutron_rabbit_password,
  $neutron_admin_password,
  $ssl_cert_file_contents,
  $br_name,
  $controller_management_address,
  $controller_public_address,
) {
  class { '::infracloud::compute':
    nova_rabbit_password          => $nova_rabbit_password,
    neutron_rabbit_password       => $neutron_rabbit_password,
    neutron_admin_password        => $neutron_admin_password,
    ssl_cert_file_contents        => $ssl_cert_file_contents,
    br_name                       => $br_name,
    controller_management_address => $controller_management_address,
    controller_public_address     => $controller_public_address,
  }

  realize (
    User::Virtual::Localuser['greghaynes'],
    User::Virtual::Localuser['krinkle'],
    User::Virtual::Localuser['rcarrillocruz'],
  )

}
