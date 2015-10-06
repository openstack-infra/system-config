# == Class: openstack_project::stackalytics
#
class openstack_project::infracloud_compute (
  $controller_management_address,
  $controller_public_address,
  $neutron_admin_password,
  $neutron_rabbit_password,
  $nova_rabbit_password,
  $gerrit_ssh_user,
  $stackalytics_ssh_private_key,
  $vhost_name = $::fqdn,
) {
  class { '::infracloud::compute':
    nova_rabbit_password             => $nova_rabbit_password,
    neutron_rabbit_password          => $neutron_rabbit_password,
    neutron_admin_password           => $neutron_admin_password,
    controller_public_address        => $controller_public_address,
    controller_management_address    => $controller_management_address,
  }

  realize (
    User::Virtual::Localuser['rcarrillocruz'],
  )
}
