# == Class: openstack_project::zuul_merger
#
class openstack_project::zuul_merger(
  $vhost_name = $::fqdn,
  $gearman_server = '127.0.0.1',
  $gerrit_server = '',
  $gerrit_user = '',
  $gerrit_ssh_host_key = '',
  $gerrit_ssh_host_identity,
  $zuul_ssh_private_key = '',
  $zuul_url = "http://${::fqdn}/p",
  $sysadmins = [],
  $git_email = 'jenkins@openstack.org',
  $git_name = 'OpenStack Jenkins',
) {

  # Create known_hosts_content
  $known_hosts_content = inline_template('<%= (@gerrit_ssh_host_identity).join(",") %> <%= @gerrit_ssh_host_key %>')

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }

  class { 'openstackci::zuul_merger':
    vhost_name               => $vhost_name,
    gearman_server           => $gearman_server,
    gerrit_server            => $gerrit_server,
    gerrit_user              => $gerrit_user,
    known_hosts_content      => $known_hosts_content,
    zuul_ssh_private_key     => $zuul_ssh_private_key,
    zuul_url                 => $zuul_url,
    git_email                => $git_email,
    git_name                 => $git_name,
    manage_common_zuul       => true,
  }
}
