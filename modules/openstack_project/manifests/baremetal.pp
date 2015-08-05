# == Class: openstack_project::baremetal
#
class openstack_project::baremetal (
  $ironic_db_password,
  $ipmi_passwords,
  $mysql_password,
  $region,
) {
  class { '::infracloud::bifrost':
    ironic_db_password   => $ironic_db_password,
    mysql_password       => $mysql_password,
    region               => $region,
    ipmi_passwords       => $ipmi_passwords,
  }

  realize (
    User::Virtual::Localuser['rcarrillocruz'],
  )
}
