class openstack_project::infracloud::compute (
  $nova_rabbit_password,
  $neutron_rabbit_password,
  $neutron_admin_password,
  $br_name,
  $controller_management_address,
  $controller_public_address,
  $ssl_chain_file_contents,
) {
  class { '::infracloud::cacert':
    cacert_content => $ssl_chain_file_contents,
  }

  class { '::infracloud::compute':
    nova_rabbit_password          => $nova_rabbit_password,
    neutron_rabbit_password       => $neutron_rabbit_password,
    neutron_admin_password        => $neutron_admin_password,
    br_name                       => $br_name,
    controller_management_address => $controller_management_address,
    controller_public_address     => $controller_public_address,
  }
}
