# == Class: openstack_project::zuul_dev
#
class openstack_project::zuul_dev(
  $vhost_name = $::fqdn,
  $gearman_server = '127.0.0.1',
  $gerrit_server = '',
  $gerrit_user = '',
  $ssh_known_hosts = undef,
  $zuul_ssh_private_key = '',
  $url_pattern = '',
  $status_url = 'http://zuul-dev.openstack.org',
  $zuul_url = '',
  $sysadmins = [],
  $statsd_host = '',
  $gearman_workers = [],
  $project_config_repo = '',
) {

  realize (
    User::Virtual::Localuser['zaro'],
  )

  # Turn a list of hostnames into a list of iptables rules
  $iptables_rules = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    iptables_rules6           => $iptables_rules,
    iptables_rules4           => $iptables_rules,
    sysadmins                 => $sysadmins,
  }

  class { 'openstackci::zuul_scheduler':
    vhost_name               => $vhost_name,
    gearman_server           => $gearman_server,
    gerrit_server            => $gerrit_server,
    gerrit_user              => $gerrit_user,
    ssh_known_hosts          => $ssh_known_hosts,
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
