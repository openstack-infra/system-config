class openstack_project::zuul_config {

  file { "/etc/zuul/layout.yaml":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/zuul/layout.yaml'
  }
  file { "/etc/zuul/openstack_functions.py":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/zuul/openstack_functions.py'
  }
  file { "/etc/zuul/logging.conf":
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/zuul/logging.conf'
  }
}
