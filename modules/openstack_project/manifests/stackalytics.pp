# == Class: openstack_project::stackalytics
#
class openstack_project::stackalytics (
) {
    class { '::stackalytics':
      gerrit_ssh_user => 'pabelanger',
      review_uri      => 'gerrit://review-dev.openstack.org',
      vhost_name      => '*',
    }
}
