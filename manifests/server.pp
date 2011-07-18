import "openstack_admins_users"

node default {
  include openstack_admins_users
  include ssh  

    package { "python-software-properties":
        ensure => latest
          }

    package { "puppet":
        ensure => latest
          }
    
    package { "bzr":
        ensure => latest
          }
    
    package { "git":
        ensure => latest
          }
    
    package { "python-setuptools":
        ensure => latest
          }
    
    package { "byobu":
        ensure => latest
          }
}
