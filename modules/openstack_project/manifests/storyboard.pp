# == Class: openstack_project::storyboard
#
class openstack_project::storyboard(
  $mysql_root_password = '',
  $mysql_password = '',
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80],
  }

  class { '::storyboard':
    mysql_root_password      => $mysql_root_password,
    mysql_password           => $mysql_password,
  }

}
