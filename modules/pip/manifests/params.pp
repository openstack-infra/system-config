# Class: pip::params
#
# This class holds parameters that need to be
# accessed by other classes.
class pip::params {
  case $::osfamily {
    'Fedora', 'Redhat': {
      $python_devel_package = 'python-devel'
      $python_pip_package     = 'python-pip'
    }
    'Debian', 'Ubuntu': {
      $python_devel_package = 'python-all-dev'
      $python_pip_package     = 'python-pip'
    }
    default: {}
  }
}
