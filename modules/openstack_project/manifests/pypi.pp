class openstack_project::pypi {
  include tmpreaper
  include apt::unattended-upgrades
  include openstack_project

  # include jenkins slave so that build deps are there for the pip download
  class { 'jenkins_slave':
    ssh_key => "",
    user => false
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80]
  }

  file { '/etc/projects.yaml':
    user => 'root',
    group => 'root',
    mode => 444,
    content => template('openstack_projects/projects.yaml'),
    replace => true,
    ensure => present,
  }

  class { "pypimirror":
    base_url => "http://pypi.openstack.org",
    projects => loadyaml('/etc/projects.yaml'),
    require => File['/etc/projects.yaml'],
  }
}
