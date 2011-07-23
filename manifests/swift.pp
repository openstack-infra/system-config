import "openstack_ci_admins_users"
import "jenkins_slave"

node default {
  include openstack_ci_admins_users
  include jenkins_slave

  apt::ppa { "ppa:swift-core/trunk":
    ensure => present
  }
  apt::builddep { "swift":
    ensure => present,
    require => Apt::Ppa["ppa:swift-core/trunk"]
  }

}
