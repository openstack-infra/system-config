# == Class: openstack_project::zuul_dev
#
class openstack_project::zuul_dev(
  $vhost_name = $::fqdn,
  $gearman_server = '127.0.0.1',
  $gerrit_server = '',
  $gerrit_user = '',
  $gerrit_ssh_host_key = '',
  $zuul_ssh_private_key = '',
  $url_pattern = '',
  $status_url = 'http://zuul-dev.openstack.org',
  $zuul_url = '',
  $statsd_host = '',
  $project_config_repo = '',
) {

  realize (
    User::Virtual::Localuser['zaro'],
  )

  class { 'openstackci::zuul_scheduler':
    vhost_name               => $vhost_name,
    gearman_server           => $gearman_server,
    gerrit_server            => $gerrit_server,
    gerrit_user              => $gerrit_user,
    known_hosts_content      => "review-dev.openstack.org,23.253.78.13,2001:4800:7817:101:be76:4eff:fe04 ${gerrit_ssh_host_key}",
    zuul_ssh_private_key     => $zuul_ssh_private_key,
    url_pattern              => $url_pattern,
    zuul_url                 => $zuul_url,
    job_name_in_report       => true,
    status_url               => $status_url,
    statsd_host              => $statsd_host,
    git_email                => 'jenkins@openstack.org',
    git_name                 => 'OpenStack Jenkins',
    project_config_repo      => $project_config_repo,
    project_config_base      => 'dev/',
  }

  class { 'openstackci::zuul_merger':
    manage_common_zuul => false,
  }
}
