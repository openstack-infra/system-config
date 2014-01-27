# == Class: openstack_project::single_use_slave
#
# This class configures single use Jenkins slaves with a few
# toggleable options. Most importantly sudo rights for the Jenkins
# user are by default off but can be enabled. Also, automatic_upgrades
# are off by default as the assumption is the backing image for
# this single use slaves will be refreshed with new packages
# periodically.
class openstack_project::single_use_slave (
  $certname = $::fqdn,
  $install_users = true,
  $sudo = false,
  $automatic_upgrades = false,
  $ssh_key = $openstack_project::jenkins_ssh_key
) inherits openstack_project {
  class { 'openstack_project::template':
    certname           => $certname,
    automatic_upgrades => $automatic_upgrades,
    install_users      => $install_users,
  }
  class { 'jenkins::slave':
    ssh_key => $ssh_key,
    sudo    => $sudo,
    bare    => true,
  }
}
