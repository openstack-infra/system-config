# == Class: openstack_project::mirror
#
class openstack_project::mirror (
  $vhost_name = $::fqdn,
) {

  $mirror_root = '/afs/openstack.org/mirror'

}
