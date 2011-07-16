import "openstack_ci_admins_users"
import "jenkins_slave"

node default {
  include openstack_ci_admins_users
  include jenkins_slave

package { "python-argparse":
  ensure => latest
}
package { "python-decorator":
  ensure => latest
}
package { "python-eventlet":
  ensure => latest
}
package { "python-formencode":
  ensure => latest
}
package { "python-greenlet":
  ensure => latest
}
package { "python-migrate":
  ensure => latest
}
package { "python-mox":
  ensure => latest
}
package { "python-netifaces":
  ensure => latest
}
package { "python-openid":
  ensure => latest
}
package { "python-openssl":
  ensure => latest
}
package { "python-paste":
  ensure => latest
}
package { "python-pastedeploy":
  ensure => latest
}
package { "python-pastescript":
  ensure => latest
}
package { "python-routes":
  ensure => latest
}
package { "python-scgi":
  ensure => latest
}
package { "python-sqlalchemy":
  ensure => latest
}
package { "python-sqlalchemy-ext":
  ensure => latest
}
package { "python-swift":
  ensure => latest
}
package { "python-tempita":
  ensure => latest
}
package { "python-webob":
  ensure => latest
}
package { "python-xattr":
  ensure => latest
}

}
