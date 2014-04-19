# == Class: openstack_project::paste
#
class openstack_project::paste (
  $mysql_password,
  $mysql_host = 'localhost',
  $mysql_user = 'openstack',
  $mysql_db_name = 'openstack',
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include lodgeit
  lodgeit::site { 'openstack':
    mysql_host     => $mysql_host,
    mysql_user     => $mysql_user,
    mysql_password => $mysql_password,
    mysql_db_name  => $mysql_db_name,
    port           => '5000',
    image          => 'header-bg2.png',
  }
}
