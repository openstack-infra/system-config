class openstack_project::review_dev {
  class { 'openstack_project::gerrit':
    ssl_cert_file => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
    ssl_key_file => '/etc/ssl/private/ssl-cert-snakeoil.key',
    ssl_chain_file => '',
    email => "review-dev@openstack.org",
    github_projects => [ {
                         name => 'gtest-org/test',
                         close_pull => 'true'
                         } ],
    war => 'http://tarballs.openstack.org/ci/gerrit-2.4.2-10-g93ffc27.war',
    script_user => 'update',
    script_key_file => '/home/gerrit2/.ssh/id_rsa',
    github_user => 'openstack-gerrit-dev',
    github_token => hiera('gerrit_dev_github_token'),
    mysql_password => hiera('gerrit_dev_mysql_password'),
    email_private_key => hiera('gerrit_dev_email_private_key')
  }
}
