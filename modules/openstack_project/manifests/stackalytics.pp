# == Class: openstack_project::stackalytics
#
class openstack_project::stackalytics (
  $stackalytics_ssh_private_key = '',
  $vhost_name = $::fqdn,
) {
  class { '::stackalytics':
    stackalytics_ssh_private_key => $stackalytics_ssh_private_key,
    vhost_name                   => $vhost_name,
  }

  realize (
    User::Virtual::Localuser['pabelanger'],
  )
}
