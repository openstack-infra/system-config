class openstack_project::zuul_config {
  include ::zuul

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
