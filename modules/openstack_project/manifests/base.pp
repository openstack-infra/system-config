# == Class: openstack_project::base
#
class openstack_project::base(
  $certname              = $::fqdn,
  $install_users         = true,
  $pin_puppet            = '3.',
  $ca_server             = undef,
) {

}

# vim:sw=2:ts=2:expandtab:textwidth=79
