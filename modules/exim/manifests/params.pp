# Class: exim::params
#
# This class holds parameters that need to be
# accessed by other classes.
class exim::params {
  case $::osfamily {
    'RedHat': {
      $package = 'exim'
      $service_name = 'exim'
      $config_file = '/etc/exim/exim.conf'
      $conf_dir = '/etc/exim/'
      $sysdefault_file = '/etc/sysconfig/exim'
    }
    'Debian': {
      $package = 'exim4-daemon-light'
      $service_name = 'exim4'
      $config_file = '/etc/exim4/exim4.conf'
      $conf_dir = '/etc/exim4'
      $sysdefault_file = '/etc/default/exim4'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'exim' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
