class openstack_project::zuul {
  class { '::zuul': }
  file { "/etc/zuul/layout.yaml":
    ensure => 'present',
    source => 'puppet:///modules/openstack_ci/zuul/layout.yaml'
  }
  file { "/etc/zuul/openstack_functions.py":
    ensure => 'present',
    source => 'puppet:///modules/openstack_ci/zuul/openstack_functions.py'
  }
  file { "/etc/zuul/logging.conf":
    ensure => 'present',
    source => 'puppet:///modules/openstack_ci/zuul/logging.conf'
  }
  file { "/etc/default/jenkins":
    ensure => 'present',
    source => 'puppet:///modules/openstack_ci/jenkins/jenkins.default'
  }
}
