import "openstack_ci_admins_users"
import "jenkins_slave"

node default {
  include openstack_ci_admins_users
  include jenkins_slave

  package { "python-storm":
    ensure => present
  }

  package { "python-mako":
    ensure => present
  }

  package { "python-pychart":
    ensure => present
  }

  package { "planet-venus":
    ensure => present
  }

  package { "nginx":
    ensure => present
  }
}
