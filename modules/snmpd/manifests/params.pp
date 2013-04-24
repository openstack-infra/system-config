# Class: snmpd::params
#
# This class holds parameters that need to be
# accessed by other classes.
class snmpd::params {
  case $::osfamily {
    'RedHat': {
      $package_name = 'net-snmp'
    }
    'Debian', 'Ubuntu': {
      $package_name = 'snmpd'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'snmpd' module only supports osfamily Ubuntu or Redhat(slaves only).")
    }
  }
}
