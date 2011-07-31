import "openstack_ci_admins_users"
import "doc_server"

node default {
  include openstack_ci_admins_users
  include doc_server
}
