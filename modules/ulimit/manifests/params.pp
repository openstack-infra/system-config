# Class: ulimit::params
#
# This class holds parameters that need to be
# accessed by other classes.
class ulimit::params {
  case $::osfamily {
    'Fedora', 'Redhat': {
      $pam_packages = ['pam']
    }
    'Debian', 'Ubuntu': {
      $pam_packages = ['libpam-modules', 'libpam-modules-bin']
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'ulimit' module only supports osfamily Fedora, Redhat, Debian, or Ubuntu.")
    }
  }
}
