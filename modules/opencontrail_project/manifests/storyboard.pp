# == Class: opencontrail_project::storyboard
#
class opencontrail_project::storyboard(
  $mysql_host = '',
  $mysql_password = '',
  $mysql_user = '',
  $sysadmins = [],
) {
  class { 'opencontrail_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80],
  }

  class { '::storyboard':
    mysql_host     => $mysql_host,
    mysql_password => $mysql_password,
    mysql_user     => $mysql_user,
    projects_file  =>
      'puppet:///modules/opencontrail_project/review.projects.yaml',
  }

}
