class openstack_project::jenkins {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 4155]
  }
  class { 'jenkins_master':
    site => 'jenkins.openstack.org',
    serveradmin => 'webmaster@openstack.org',
    logo => 'openstack.png',
    ssl_cert_file => '/etc/ssl/certs/jenkins.openstack.org.pem',
    ssl_key_file => '/etc/ssl/private/jenkins.openstack.org.key',
    ssl_chain_file => '/etc/ssl/certs/intermediate.pem',
  }
  class { "jenkins_jobs":
    url => "https://jenkins.openstack.org/",
    username => "gerrig",
    password => hiera('jenkins_jobs_password'),
    site => "openstack",
  }
  class { "openstack_project::zuul": }
}
