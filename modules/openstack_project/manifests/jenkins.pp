class openstack_project::jenkins($jenkins_jobs_password) {

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

  class { "jenkins_job_builder":
    url => "https://jenkins.openstack.org/",
    username => "gerrig",
    password => $jenkins_jobs_password,
  }

  file { '/etc/jenkins_jobs/config':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    source => ['puppet:///modules/openstack_project/jenkins_job_builder/config'],
    notify => Exec["jenkins_jobs_update"]
  }

  file { "/etc/default/jenkins":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/jenkins/jenkins.default'
  }

}
