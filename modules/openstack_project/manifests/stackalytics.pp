# == Class: openstack_project::stackalytics
#
class openstack_project::stackalytics (
  $gerrit_host = 'review.openstack.org',
  $gerrit_ssh_user = 'stackalytics',
  $stackalytics_ssh_private_key = '',
  $vhost_name = $::fqdn,
) {
  class { '::stackalytics':
    gerrit_host                  => $gerrit_host,
    gerrit_ssh_user              => $gerrit_ssh_user,
    stackalytics_ssh_private_key => $stackalytics_ssh_private_key,
    vhost_name                   => $vhost_name,
  }

  realize (
    User::Virtual::Localuser['pabelanger'],
  )
}
