# Class: openstack_project::params
#
# This class holds parameters that need to be
# accessed by other classes.
class openstack_project::params {
  case $::osfamily {
    'RedHat': {
      $packages = ['parted', 'puppet', 'wget', 'iputils']
      $user_packages = ['emacs-nox', 'vim-enhanced']
      $login_defs = 'puppet:///modules/openstack_project/login.defs.redhat'
    }
    'Debian': {
      $packages = ['parted', 'puppet', 'wget', 'iputils-ping']
      case $::operatingsystemrelease {
        /^(12|14)\.(04|10)$/: {
          $user_packages = ['emacs23-nox', 'vim-nox', 'iftop',
                            'sysstat', 'iotop']
        }
        default: {
          $user_packages = ['emacs-nox', 'vim-nox']
        }
      }
      $login_defs = 'puppet:///modules/openstack_project/login.defs.debian'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'openstack_project' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
