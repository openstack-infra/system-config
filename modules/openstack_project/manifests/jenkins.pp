# == Class: openstack_project::jenkins
#
class openstack_project::jenkins (
  $vhost_name = $::fqdn,
  $jenkins_password = '',
  $jenkins_username = 'gerrig', # This is not a typo, well it isn't anymore.
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $jenkins_ssh_public_key,
  $jenkins_ssh_private_key = '',
  $project_config_repo = '',
  $project_config_base = '',
  $serveradmin = 'webmaster@openstack.org',
  $logo = 'openstack.png',
) {

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
    project_config_repo     => $project_config_repo,
    project_config_base     => $project_config_base,
    jenkins_username        => $jenkins_username,
    jenkins_password        => $jenkins_password,
    jenkins_url             => "https://${vhost_name}/",
    manage_jenkins_jobs     => true,
  }
}
