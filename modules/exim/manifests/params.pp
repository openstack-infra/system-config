# Class: exim::params
#
# This class holds parameters that need to be
# accessed by other classes.
class exim::params {
  case $::osfamily {
    'Redhat': {
      $package = 'exim'
      $service_name = 'exim'
      $config_file = '/etc/exim/exim.conf'
      $conf_dir = '/etc/exim/'
    }
    'Debian', 'Ubuntu': {
      $package = 'exim4-daemon-light'
      $service_name = 'exim4'
      $config_file = '/etc/exim4/exim4.conf'
      $conf_dir = '/etc/exim4'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'exim' module only supports osfamily Ubuntu or Redhat(slaves only).")
    }
  }
}
