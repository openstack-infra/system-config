class openstack_project::jenkins($jenkins_jobs_password, $zuul_user, $zuul_apikey, $gerrit_server, $gerrit_user) {

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
    password => $jenkins_jobs_password,
    site => "openstack",
  }
  file { "/etc/default/jenkins":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/jenkins/jenkins.default'
  }

  class { "zuul":
    jenkins_server => "https://$fqdn",
    jenkins_user => $zuul_user,
    jenkins_apikey => $zuul_apikey,
    gerrit_server => $gerrit_server,
    gerrit_user => $gerrit_user,
  }

  file { "/etc/zuul/layout.yaml":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/zuul/layout.yaml',
    notify => Exec['zuul-reload'],
  }
  file { "/etc/zuul/openstack_functions.py":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/zuul/openstack_functions.py',
    notify => Exec['zuul-reload'],
  }
  file { "/etc/zuul/logging.conf":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/zuul/logging.conf',
    notify => Exec['zuul-reload'],
  }
}
