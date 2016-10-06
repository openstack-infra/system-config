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
  $statsd_host = '',
  $gearman_workers = [],
  $project_config_repo = '',
  $project_config_base = 'dev/',
  $osic_cloud1_username           = hiera('nodepool_osic_cloud1_username', 'username'),
  $osic_cloud1_password           = hiera('nodepool_osic_cloud1_password'),
  $osic_cloud1_project            = hiera('nodepool_osic_cloud1_project', 'project'),
  $infracloud_vanilla_username    = hiera('nodepool_infracloud_vanilla_username', 'username'),
  $infracloud_vanilla_password    = hiera('nodepool_infracloud_vanilla_password'),
  $infracloud_vanilla_project     = hiera('nodepool_infracloud_vanilla_project', 'project'),
  $infracloud_chocolate_username  = hiera('nodepool_infracloud_chocolate_username', 'username'),
  $infracloud_chocolate_password  = hiera('nodepool_infracloud_chocolate_password'),
  $infracloud_chocolate_project   = hiera('nodepool_infracloud_chocolate_project', 'project'),
  $clouds_yaml = template("openstack_project/nodepool/clouds-dev.yaml.erb"),
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
    project_config_base      => $project_config_base,
  }

  class { 'openstackci::zuul_merger':
    gearman_server       => 'zuul-dev.openstack.org',
    gerrit_server        => 'review-dev.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_dev_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('zuul_dev_ssh_private_key_contents'),
    sysadmins            => hiera('sysadmins', []),
  }

  class { 'openstackci::zuul_launcher':
    status_url           => $status_url,
    gearman_server       => 'zuul-dev.openstack.org',
    gerrit_server        => 'review-dev.openstack.org',
    gerrit_user          => 'jenkins',
    gerrit_ssh_host_key  => hiera('gerrit_dev_ssh_rsa_pubkey_contents'),
    zuul_ssh_private_key => hiera('zuul_dev_ssh_private_key_contents'),
    project_config_repo  => 'https://git.openstack.org/openstack-infra/project-config',
    sysadmins            => hiera('sysadmins', []),
    sites                => hiera('zuul_sites', []),
    nodes                => hiera('zuul_nodes', []),
    accept_nodes         => false,
    }
  }

  include openstack_project   # needed by nodepool

  class { '::openstackci::nodepool':
    vhost_name                    => 'zuul-dev.openstack.org',
    project_config_repo           => 'https://git.openstack.org/openstack-infra/project-config',
    mysql_password                => hiera('nodepool_mysql_password'),
    mysql_root_password           => hiera('nodepool_mysql_root_password'),
    nodepool_ssh_public_key       => hiera('zuul_worker_ssh_public_key_contents'),
    # TODO(pabelanger): Switch out private key with zuul_worker once we are
    # ready.
    nodepool_ssh_private_key      => hiera('jenkins_ssh_private_key_contents'),
    oscc_file_contents            => $clouds_yaml,
    image_log_document_root       => '/var/log/nodepool/image',
    logging_conf_template         => 'openstack_project/nodepool/nodepool.logging.conf.erb',
    builder_logging_conf_template => 'openstack_project/nodepool/nodepool-builder.logging.conf.erb',
    upload_workers                => '1',
    jenkins_masters               => [],
    split_daemon                  => true,
    project_config_repo           => $project_config_repo,
    project_config_base           => $project_config_base,
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
