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
  $default_network_interface,
  $dhcp_pool_start,
  $dhcp_pool_end,
  $network_interface,
  $ipv4_nameserver,
  $ipv4_subnet_mask,
) {
  class { '::infracloud::bifrost':
    bridge_name               => $bridge_name,
    ironic_db_password        => $ironic_db_password,
    mysql_password            => $mysql_password,
    ipmi_passwords            => $ipmi_passwords,
    ssh_private_key           => $ssh_private_key,
    ssh_public_key            => $ssh_public_key,
    vlan                      => $vlan,
    gateway_ip                => $gateway_ip,
    default_network_interface => $default_network_interface,
    dhcp_pool_start           => $dhcp_pool_start,
    dhcp_pool_end             => $dhcp_pool_end,
    network_interface         => $network_interface,
    ipv4_nameserver           => $ipv4_nameserver,
    ipv4_subnet_mask          => $ipv4_subnet_mask,
  }

  realize (
    User::Virtual::Localuser['colleen'],
  )

}
