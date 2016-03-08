# == Class: openstack_project::stackalytics
#
class openstack_project::stackalytics (
  $gerrit_ssh_user,
  $stackalytics_ssh_private_key,
  $vhost_name = $::fqdn,
) {
  class { '::stackalytics':
    gerrit_ssh_user              => $gerrit_ssh_user,
    stackalytics_ssh_private_key => $stackalytics_ssh_private_key,
    vhost_name                   => $vhost_name,
  }
}
