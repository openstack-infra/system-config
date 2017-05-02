# == Class: openstack_project::template
#
# A template host with no running services
#
class openstack_project::template (
  $pin_puppet                = '3.',
  $install_resolv_conf       = true,
  $certname                  = $::fqdn,
  $ca_server                 = undef,
  $afs                       = false,
  $puppetmaster_server       = 'puppetmaster.openstack.org',
  $sysadmins                 = [],
  $permit_root_login         = 'no',
) {

}
