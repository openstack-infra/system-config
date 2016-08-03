# == Class: openstack_project::stackalytics
#
class openstack_project::stackalytics (
  $ssh_known_hosts,
  $gerrit_ssh_user,
  $stackalytics_ssh_private_key,
  $vhost_name = $::fqdn,
) {
  class { '::stackalytics':
    ssh_known_hosts              => $ssh_known_hosts,
    gerrit_ssh_user              => $gerrit_ssh_user,
    stackalytics_ssh_private_key => $stackalytics_ssh_private_key,
    vhost_name                   => $vhost_name,
  }
}
