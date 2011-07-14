import "openstack_ci_admins_users"
import "static_users"
import "jenkins_slave"

node default {
  include openstack_ci_admins_users
  include static_users
  include jenkins_slave
}
