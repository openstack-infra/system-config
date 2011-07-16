import "openstack_ci_admins_users"
import "jenkins_slave"

node default {
  include openstack_ci_admins_users
  include jenkins_slave

  package { "python-eventlet":
    ensure => latest
  }
}
