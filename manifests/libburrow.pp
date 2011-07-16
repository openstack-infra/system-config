import "openstack_ci_admins_users"
import "jenkins_slave"

node default {
  include openstack_ci_admins_users
  include jenkins_slave

  package { "build-essential":
    ensure => latest
  }

  package { "libcurl4-gnutls-dev":
    ensure => latest
  }

  package { "libtool":
    ensure => latest
  }

  package { "autoconf":
    ensure => latest
  }

  package { "automake":
    ensure => latest
  }
}
