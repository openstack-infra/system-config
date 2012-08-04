class openstack_project::review_dev(
  $github_oauth_token,
  $mysql_password,
  $mysql_root_password,
  $email_private_key) {
  class { 'openstack_project::gerrit':
    vhost_name => 'review-dev.openstack.org',
    canonicalweburl => "https://review-dev.openstack.org/",
    ssl_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file => '',
    email => "review-dev@openstack.org",
    war => 'http://tarballs.openstack.org/ci/gerrit-2.4.2-11-gb5a28fb.war',
    projects_file => 'puppet:///openstack_project/review-dev.projects.yaml',
    github_username => 'openstack-gerrit-dev',
    github_oauth_token => $github_oauth_token,
    mysql_password => $mysql_password,
    mysql_root_password => $mysql_root_password,
    email_private_key => $email_private_key,
  }
}
