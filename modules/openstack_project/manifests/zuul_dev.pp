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
  $zuul_url = '',
  $status_url = 'http://zuul-dev.openstack.org/zuul/',
  $sysadmins = [],
  $statsd_host = '',
  $project_config_repo = 'https://git.openstack.org/openstack-infra/project-config',
  $gearman_workers = [],
  $zuul_launcher_keytab = '',
  $mysql_password = '',
  $mysql_root_password = '',
  $nodepool_ssh_public_key = '',
  $osic_cloud8_username           = '',
  $osic_cloud8_password           = '',
  $osic_cloud8_project            = '',
  $clouds_yaml          = '',
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
    vhost_name               => $vhost_name,
    gearman_server           => $gearman_server,
    gerrit_server            => $gerrit_server,
    gerrit_user              => $gerrit_user,
    zuul_ssh_private_key     => $zuul_ssh_private_key,
    url_pattern              => $url_pattern,
    zuul_url                 => $zuul_url,
    job_name_in_report       => true,
    status_url               => $status_url,
    statsd_host              => $statsd_host,
    git_email                => 'jenkins@openstack.org',
    git_name                 => 'OpenStack Jenkins',
  }

  class { 'openstackci::zuul_scheduler2':
    known_hosts_content      => "review-dev.openstack.org,23.253.78.13,2001:4800:7817:101:be76:4eff:fe04 ${gerrit_ssh_host_key}",
    project_config_repo      => $project_config_repo,
    project_config_base      => 'dev/',
  }

  class { 'openstackci::zuul_merger':
    manage_common_zuul => false,
  }

  class { 'openstack_project::zuul_launcher':
    project_config_repo      => $project_config_repo,
    project_config_base      => 'dev/',
    zuul_launcher_keytab     => $zuul_launcher_keytab,
  }

  include openstack_project

  class { '::openstackci::nodepool':
    vhost_name                    => '127.0.0.1',
    project_config_repo           => $project_config_repo,
    mysql_password                => $mysql_password,
    mysql_root_password           => $mysql_root_password,
    nodepool_ssh_public_key       => $nodepool_ssh_public_key,
    # TODO(pabelanger): Switch out private key with zuul_worker once we are
    # ready.
    nodepool_ssh_private_key      => hiera('jenkins_dev_ssh_private_key_contents'),
    oscc_file_contents            => $clouds_yaml,
    image_log_document_root       => '/var/log/nodepool/image',
    statsd_host                   => 'graphite.openstack.org',
    logging_conf_template         => 'openstack_project/nodepool/nodepool.logging.conf.erb',
    builder_logging_conf_template => 'openstack_project/nodepool/nodepool-builder.logging.conf.erb',
    upload_workers                => '16',
    jenkins_masters               => [],
    split_daemon                  => true,
    bluebox_username              => '',
    bluebox_password              => '',
    bluebox_project               => '',
    rackspace_username            => '',
    rackspace_password            => '',
    rackspace_project             => '',
    hpcloud_username              => '',
    hpcloud_password              => '',
    hpcloud_project               => '',
    internap_username             => '',
    internap_password             => '',
    internap_project              => '',
    ovh_username                  => '',
    ovh_password                  => '',
    ovh_project                   => '',
    tripleo_username              => '',
    tripleo_password              => '',
    tripleo_project               => '',
    infracloud_vanilla_username   => '',
    infracloud_vanilla_password   => '',
    infracloud_vanilla_project    => '',
    infracloud_chocolate_username => '',
    infracloud_chocolate_password => '',
    infracloud_chocolate_project  => '',
    osic_cloud1_username          => '',
    osic_cloud1_password          => '',
    osic_cloud1_project           => '',
    osic_cloud8_username          => $osic_cloud8_username,
    osic_cloud8_password          => $osic_cloud8_password,
    osic_cloud8_project           => $osic_cloud8_project,
    vexxhost_username             => '',
    vexxhost_password             => '',
    vexxhost_project              => '',
    vexxhost_project              => '',
    datacentred_password          => '',
    datacentred_project           => '',
    citycloud_username            => '',
    citycloud_password            => '',
  }
  file { '/home/nodepool/.config/openstack/infracloud_vanilla_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('infracloud_vanilla_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool'],
  }
  file { '/home/nodepool/.config/openstack/infracloud_chocolate_cacert.pem':
    ensure  => present,
    owner   => 'nodepool',
    group   => 'nodepool',
    mode    => '0600',
    content => hiera('infracloud_chocolate_ssl_cert_file_contents'),
    require => Class['::openstackci::nodepool'],
  }
}
