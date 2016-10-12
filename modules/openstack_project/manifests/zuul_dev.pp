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
  $sysadmins = [],
  $sites = [],
  $nodes = [],
  $zuul_launcher_keytab = '',
  $statsd_host = '',
  $gearman_workers = [],
  $project_config_repo = '',
  $project_config_base = 'dev/',
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

  class { '::zuul':
    vhost_name              => $vhost_name,
    gearman_server          => $gearman_server,
    gerrit_server           => $gerrit_server,
    gerrit_user             => $gerrit_user,
    zuul_ssh_private_key    => $zuul_ssh_private_key,
    zuul_url                => $zuul_url,
    git_email               => $git_email,
    git_name                => $git_name,
    revision                => $revision,
    git_source_repo         => $git_source_repo,
    jenkins_jobs            => '/etc/jenkins_jobs/config',
    workspace_root          => $workspace_root,
    worker_private_key_file => $worker_private_key_file,
    worker_username         => $worker_username,
    sites                   => $sites,
    nodes                   => $nodes,
    accept_nodes            => $accept_nodes,
  }

  class { 'openstackci::zuul_scheduler':
    known_hosts_content      => "review-dev.openstack.org,23.253.78.13,2001:4800:7817:101:be76:4eff:fe04 ${gerrit_ssh_host_key}",
    project_config_repo      => $project_config_repo,
    project_config_base      => $project_config_base,
  }

  class { 'openstackci::zuul_merger':
    manage_common_zuul => false,
  }

  class { 'openstackci::zuul_launcher':
    status_url           => $status_url,
    gearman_server       => $gearman_server,
    gerrit_server        => $gerrit_server,
    gerrit_user          => $gerrit_user,
    gerrit_ssh_host_key  => $gerrit_ssh_host_key,
    zuul_ssh_private_key => $zuul_ssh_private_key,
    project_config_repo  => $project_config_repo,
    project_config_base  => $project_config_base,
    sysadmins            => $sysadmins,
    sites                => $sites,
    nodes                => $nodes,
    zuul_launcher_keytab => $zuul_launcher_keytab,
    accept_nodes         => false,
    }
}
