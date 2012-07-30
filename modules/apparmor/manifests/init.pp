# Creating an apparmor service class
# so we can notify the service when 
# apparmor files are changed by puppet.
# This probably isn't included in your
# class, so if you need to notify this
# service make sure you include it.
class apparmor {
  package { "apparmor":
    ensure => present
  }
  service { "apparmor":
    ensure => 'running';
  }
}
