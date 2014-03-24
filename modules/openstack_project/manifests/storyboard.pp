# == Class: openstack_project::storyboard
#
class openstack_project::storyboard(
  $mysql_host = '',
  $mysql_password = '',
  $mysql_user = '',
  $sysadmins = [],
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
) {
  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80, 443],
  }

  class { '::storyboard':
    mysql_host              => $mysql_host,
    mysql_password          => $mysql_password,
    mysql_user              => $mysql_user,
    projects_file           =>
      'puppet:///modules/openstack_project/review.projects.yaml',
    superusers_file         =>
      'puppet:///modules/openstack_project/storyboard/superusers.yaml',
    ssl_cert_file           =>
      '/etc/ssl/certs/storyboard.openstack.org.pem',
    ssl_key_file            =>
      '/etc/ssl/private/storyboard.openstack.org.key',
    ssl_chain_file          => '/etc/ssl/certs/intermediate.pem',
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
  }

}
