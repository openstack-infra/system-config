# bare-bones slaves spun up by jclouds. Specifically need to not set ssh
# login limits, because it screws up jclouds provisioning
class openstack_project::bare_slave(
  $certname = $::fqdn,
  $install_users = true
) {
  class { 'openstack_project::base':
    certname      => $certname,
    install_users => $install_users,
  }

  class { 'jenkins::slave':
    ssh_key => '',
    user    => false
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
