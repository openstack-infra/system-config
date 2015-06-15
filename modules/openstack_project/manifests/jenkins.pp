# == Class: openstack_project::jenkins
#
class openstack_project::jenkins (
  $vhost_name = $::fqdn,
  $jenkins_jobs_password = '',
  $jenkins_jobs_username = 'gerrig', # This is not a typo, well it isn't anymore.
  $jenkins_git_url = 'https://git.openstack.org/openstack-infra/jenkins-job-builder',
  $jenkins_git_revision = 'master',
  $manage_jenkins_jobs = true,
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $jenkins_ssh_public_key = $openstack_project::jenkins_ssh_key,
  $jenkins_ssh_private_key = '',
  $project_config_repo = '',
  $serveradmin = 'webmaster@openstack.org',
  $logo = 'openstack.png',
) inherits openstack_project {
  include openstack_project

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

  class { 'openstackci::jenkins_master':
    vhost_name              => $vhost_name,
    serveradmin             => $serveradmin,
    logo                    => $logo,
    ssl_cert_file           => $prv_ssl_cert_file,
    ssl_key_file            => $prv_ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    jenkins_ssh_private_key => $jenkins_ssh_private_key,
    jenkins_ssh_public_key  => $jenkins_ssh_public_key,
  }

  if $manage_jenkins_jobs == true {
    class { 'project_config':
      url  => $project_config_repo,
    }

    class { '::jenkins::job_builder':
      jenkins_jobs_update_timeout => 1200,
      url                         => "https://${vhost_name}/",
      username                    => $jenkins_jobs_username,
      password                    => $jenkins_jobs_password,
      git_revision                => $jenkins_git_revision,
      git_url                     => $jenkins_git_url,
      config_dir                  =>
        $::project_config::jenkins_job_builder_config_dir,
      require                     => $::project_config::config_dir,
    }
  }
}
