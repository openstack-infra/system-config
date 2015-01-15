# Class: openstack_project::params
#
# This class holds parameters that need to be
# accessed by other classes.
class openstack_project::params {
  case $::osfamily {
    'RedHat': {
      $packages = ['puppet', 'wget']
      $user_packages = ['byobu', 'emacs-nox', 'vim-minimal']
      $update_pkg_list_cmd = ''
      $login_defs = 'puppet:///modules/openstack_project/login.defs.redhat'
    }
    'Debian': {
      $packages = ['puppet', 'wget']
      $user_packages = ['byobu', 'emacs23-nox', 'vim-nox']
      $update_pkg_list_cmd = 'apt-get update >/dev/null 2>&1;'
      $login_defs = 'puppet:///modules/openstack_project/login.defs.debian'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'openstack_project' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
