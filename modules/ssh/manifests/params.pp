# Class: ssh::params
#
# This class holds parameters that need to be
# accessed by other classes.
class ssh::params {
  case $::osfamily {
    'RedHat': {
      $package_name = 'openssh-server'
      $service_name = 'sshd'
    }
    'Debian': {
      $package_name = 'openssh-server'
      $service_name = 'ssh'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'ssh' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
