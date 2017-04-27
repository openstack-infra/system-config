# == Class: openstack_project::single_use_slave
#
# This class configures single use Jenkins slaves with a few
# toggleable options. Most importantly sudo rights for the Jenkins
# user are by default off but can be enabled.
class openstack_project::single_use_slave (
  $certname = $::fqdn,
  $install_resolv_conf = true,
  $sudo = false,
  # TODO(pabelanger): To be removed in a future patch.
  $ssh_key = $openstack_project::jenkins_ssh_key,
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
) inherits openstack_project {
}
