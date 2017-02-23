# Class: openstack_project::params
#
# This class holds parameters that need to be
# accessed by other classes.
class openstack_project::params {
  case $::osfamily {
    'RedHat': {
      $packages = ['parted', 'puppet', 'wget', 'iputils']
      $user_packages = ['emacs-nox', 'vim-enhanced']
      $update_pkg_list_cmd = ''
      $login_defs = 'puppet:///modules/openstack_project/login.defs.redhat'
    }
    'Suse':  {
      $packages = ['parted', 'ruby2.1-rubygem-puppet', 'wget', 'iputils']
      $user_packages = ['emacs-nox', 'vim', 'sysstat']
      $update_pkg_list_cmd = ''
      $login_defs = 'puppet:///modules/openstack_project/login.defs.suse'
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
      $update_pkg_list_cmd = 'apt-get update >/dev/null 2>&1;'
      $login_defs = 'puppet:///modules/openstack_project/login.defs.debian'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'openstack_project' module only supports osfamily Debian or RedHat/Suse (slaves only).")
    }
  }
}
