# == Class: openstack_project::baremetal
#
class openstack_project::infracloud::baremetal (
  $ironic_inventory,
  $ironic_db_password,
  $ipmi_passwords,
  $mysql_password,
  $ssh_private_key,
  $ssh_public_key,
  $bridge_name,
  $vlan,
  $gateway_ip,
) {
  class { '::infracloud::bifrost':
    bridge_name          => $bridge_name,
    ironic_inventory     => $ironic_inventory,
    ironic_db_password   => $ironic_db_password,
    mysql_password       => $mysql_password,
    ipmi_passwords       => $ipmi_passwords,
    ssh_private_key      => $ssh_private_key,
    ssh_public_key       => $ssh_public_key,
    vlan                 => $vlan,
    gateway_ip           => $gateway_ip,
  }

  realize (
    User::Virtual::Localuser['colleen'],
  )

}
