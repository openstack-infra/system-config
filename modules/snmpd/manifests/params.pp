# Class: snmpd::params
#
# This class holds parameters that need to be
# accessed by other classes.
class snmpd::params {
  case $::osfamily {
    /^(RedHat|Suse)$/: {
      $package_name = 'net-snmp'
    }
    'Debian': {
      $package_name = 'snmpd'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'snmpd' module only supports osfamily Debian, RedHat or SUSE (slaves only).")
    }
  }
}
