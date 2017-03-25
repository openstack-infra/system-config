# Class: openstack_project::params
#
# This class holds parameters that need to be
# accessed by other classes.
class openstack_project::params {
  $cross_platform_packages = [
    'at',
    'git',
    'lvm2',
    'parted',
    'puppet',
    'rsync',
    'strace',
    'tcpdump',
    'wget',
  ]
  case $::osfamily {
    'RedHat': {
      $packages = concat($cross_platform_packages, ['iputils', 'bind-utils'])
      $user_packages = ['emacs-nox', 'vim-enhanced']
      $update_pkg_list_cmd = ''
      $login_defs = 'puppet:///modules/openstack_project/login.defs.redhat'
    }
    'Debian': {
      $packages = concat($cross_platform_packages, ['iputils-ping', 'dnsutils'])
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
      fail("Unsupported osfamily: ${::osfamily} The 'openstack_project' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
