# Class: pip::params
#
# This class holds parameters that need to be
# accessed by other classes.
class pip::params {
  case $::osfamily {
    'RedHat': {
      $python_devel_package = 'python-devel'
      $python3_devel_package = 'python3-devel'
      $python3_pip_package   = 'python3-pip'
    }
    'Debian': {
      $python_devel_package  = 'python-all-dev'
      $python3_devel_package = 'python3-all-dev'
      $python3_pip_package   = 'python3-pip'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'pip' module only supports osfamily Debian or RedHat.")
    }
  }
}
