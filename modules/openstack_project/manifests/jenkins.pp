# == Class: openstack_project::jenkins
#
class openstack_project::jenkins (
  $vhost_name = $::fqdn,
  $jenkins_jobs_password = '',
  $jenkins_jobs_username = 'gerrig', # This is not a typo, well it isn't anymore.
  $jenkins_git_url = 'https://git.openstack.org/openstack-infra/jenkins-job-builder',
  $jenkins_git_revision = 'master',
  $jenkins_plugins = {
    'build-timeout' => { 'version' => '1.14' },
    'copyartifact' => { 'version' => '1.22' },
    'dashboard-view' => { 'version' => '2.3' },
    'envinject' => { 'version' => '1.70' },
    'gearman-plugin' => { 'version' => '0.1.1' },
    'git' => { 'version' => '1.1.23' },
    'greenballs' => { 'version' => '1.12' },
    'extended-read-permission' => { 'version' => '1.0' },
    'zmq-event-publisher' => { 'version' => '0.0.3' },
    # TODO(jeblair): release # 'scp' => { 'version'' => '1.9' },
    'jobConfigHistory' => { 'version' => '1.13' },
    'monitoring' => { 'version' => '1.40.0' },
    'nodelabelparameter' => { 'version' => '1.2.1' },
    'notification' => { 'version' => '1.4' },
    'openid' => { 'version' => '1.5' },
    'publish-over-ftp' => { 'version' => '1.7' },
    'simple-theme-plugin' => { 'version' => '0.2' },
    'timestamper' => { 'version' => '1.3.1' },
    'token-macro' => { 'version' => '1.5.1' },
  },
  $manage_jenkins_jobs = true,
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $jenkins_ssh_private_key = '',
  $zmq_event_receivers = [],
  $sysadmins = [],
  $project_config_repo = '',
) {
  include openstack_project

  $iptables_rule = regsubst ($zmq_event_receivers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 8888 -s \1 -j ACCEPT')
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => $sysadmins,
  }

  # Set defaults here because they evaluate variables which you cannot
  # do in the class parameter list.
  if $ssl_cert_file == '' {
    $prv_ssl_cert_file = "/etc/ssl/certs/${vhost_name}.pem"
  }
  else {
    $prv_ssl_cert_file = $ssl_cert_file
  }
  if $ssl_key_file == '' {
    $prv_ssl_key_file = "/etc/ssl/private/${vhost_name}.key"
  }
  else {
    $prv_ssl_key_file = $ssl_key_file
  }

  class { '::jenkins::master':
    vhost_name              => $vhost_name,
    serveradmin             => 'webmaster@openstack.org',
    logo                    => 'openstack.png',
    ssl_cert_file           => $prv_ssl_cert_file,
    ssl_key_file            => $prv_ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    jenkins_ssh_private_key => $jenkins_ssh_private_key,
    jenkins_ssh_public_key  => $openstack_project::jenkins_ssh_key,
  }

  define install_jenkins_plugin($version) {
    jenkins::plugin { $name:
      version => $version,
    }
  }

  create_resources(install_jenkins_plugin, $jenkins_plugins)

  if $manage_jenkins_jobs == true {
    class { 'project_config':
      url  => $project_config_repo,
    }

    class { '::jenkins::job_builder':
      url          => "https://${vhost_name}/",
      username     => $jenkins_jobs_username,
      password     => $jenkins_jobs_password,
      git_revision => $jenkins_git_revision,
      git_url      => $jenkins_git_url,
      config_dir   => $::project_config::jenkins_job_builder_config_dir,
      require      => $::project_config::config_dir,
    }

    file { '/etc/default/jenkins':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/openstack_project/jenkins/jenkins.default',
    }
  }
}
