# == Class: openstack_project::zuul_prod
#
class openstack_project::zuul_prod(
  $vhost_name = $::fqdn,
  $gearman_server = '127.0.0.1',
  $gearman_check_job_registration = '',
  $gerrit_server = '',
  $gerrit_user = '',
  $gerrit_ssh_host_key = '',
  $zuul_ssh_private_key = '',
  $url_pattern = '',
  $zuul_url = '',
  $status_url = 'http://status.openstack.org/zuul/',
  $swift_account_temp_key = '',
  $swift_authurl = '',
  $swift_auth_version = '',
  $swift_user = '',
  $swift_key = '',
  $swift_tenant_name = '',
  $swift_region_name = '',
  $swift_default_container = '',
  $swift_default_logserver_prefix = '',
  $swift_default_expiry = 7200,

  $proxy_ssl_cert_file_contents = '',
  $proxy_ssl_key_file_contents = '',
  $proxy_ssl_chain_file_contents = '',
  $sysadmins = [],
  $statsd_host = '',
  $gearman_workers = [],
  $project_config_repo = '',
  $git_email = 'jenkins@openstack.org',
  $git_name = 'OpenStack Jenkins',
  $revision = '',
  $job_name_in_report = '',

  $smtp_host = '',
  $smtp_port = '',
  $smtp_default_from = '',
  $smtp_default_to = '',
  $smtp_default_from = '',
  $smtp_default_to = '',
) {
  # Turn a list of hostnames into a list of iptables rules
  $iptables_rules = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    iptables_rules6           => $iptables_rules,
    iptables_rules4           => $iptables_rules,
    sysadmins                 => $sysadmins,
  }

  class { '::zuul':
    vhost_name                     => $vhost_name,
    gearman_server                 => $gearman_server,
    gearman_check_job_registration => $gearman_check_job_registration,
    gerrit_server                  => $gerrit_server,
    gerrit_user                    => $gerrit_user,
    zuul_ssh_private_key           => $zuul_ssh_private_key,
    url_pattern                    => $url_pattern,
    layout_file_name               => $layout_file_name,
    zuul_url                       => $zuul_url,
    job_name_in_report             => $job_name_in_report,
    status_url                     => $status_url,
    statsd_host                    => $statsd_host,
    git_email                      => $git_email,
    git_name                       => $git_name,
    smtp_host                      => $smtp_host,
    smtp_port                      => $smtp_port,
    smtp_default_from              => $smtp_default_from,
    smtp_default_to                => $smtp_default_to,
    swift_account_temp_key         => $swift_account_temp_key,
    swift_authurl                  => $swift_authurl,
    swift_auth_version             => $swift_auth_version,
    swift_user                     => $swift_user,
    swift_key                      => $swift_key,
    swift_tenant_name              => $swift_tenant_name,
    swift_region_name              => $swift_region_name,
    swift_default_container        => $swift_default_container,
    swift_default_logserver_prefix => $swift_default_logserver_prefix,
    swift_default_expiry           => $swift_default_expiry,
    proxy_ssl_cert_file_contents   => $proxy_ssl_cert_file_contents,
    proxy_ssl_key_file_contents    => $proxy_ssl_key_file_contents,
    proxy_ssl_chain_file_contents  => $proxy_ssl_chain_file_contents,
    revision                       => $revision,
  }

  class { 'openstackci::zuul_scheduler':
    known_hosts_content            => "review.openstack.org,104.130.159.134,2001:4800:7818:102:be76:4eff:fe05:9b12 ${gerrit_ssh_host_key}",
    project_config_repo            => $project_config_repo,
  }
}
