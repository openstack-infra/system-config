# == Class: openstack_project::www
#
# Deploys OpenStack www site
#
class openstack_project::www (
  $dbpasswd,
  $dbname = 'www',
  $dbuser = 'www',
  $dbhost = 'localhost',
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80, 443],
  }

  include openstackweb
  # TODO(clarkb) switch to an openstackweb::params to accomodate the
  # large number of config items needed for the SS env.
  class { 'openstackweb::site':
    dbname   => $dbname,
    dbuser   => $dbuser,
    dbpasswd => $dbpasswd,
    dbhost   => $dhhost,
    require  => Class['openstackweb'],
  }

  # TODO(clarkb) DB backups
  # TODO(clarkb) offsite backups
}
