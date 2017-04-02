# == Class: openstack_project::single_use_slave
#
# This class configures single use Jenkins slaves with a few
# toggleable options. Most importantly sudo rights for the Jenkins
# user are by default off but can be enabled.
class openstack_project::single_use_slave (
  $install_resolv_conf = true,
  $sudo = false,
  $ssh_key = $openstack_project::jenkins_ssh_key,
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
) inherits openstack_project {
  class { 'openstack_project::template':
    install_resolv_conf       => $install_resolv_conf,
  }

  class { '::jenkins::jenkinsuser':
    ssh_key     => $ssh_key,
    gitfullname => $jenkins_gitfullname,
    gitemail    => $jenkins_gitemail,
  }
}
