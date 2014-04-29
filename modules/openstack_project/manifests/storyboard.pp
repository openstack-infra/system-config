# == Class: openstack_project::storyboard
#
class openstack_project::storyboard(
  $mysql_host = '',
  $mysql_password = '',
  $mysql_user = '',
  $sysadmins = [],
) {
  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80],
  }

  class { '::storyboard':
    mysql_host     => $mysql_host,
    mysql_password => $mysql_password,
    mysql_user     => $mysql_user,
    projects_file  =>
      'puppet:///modules/openstack_project/review.projects.yaml',
  }

}
