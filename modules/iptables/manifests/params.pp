# Class: iptables::params
#
# This class holds parameters that need to be
# accessed by other classes.
class iptables::params {
  case $::osfamily {
    'RedHat': {
      $package_name = 'iptables'
      $service_name = 'iptables'
      $rules_dir = '/etc/sysconfig'
      $ipv4_rules = '/etc/sysconfig/iptables'
      $ipv6_rules = '/etc/sysconfig/ip6tables'
      $service_has_status = true
      $service_status_cmd = undef
      $service_has_restart = false
    }
    'Debian': {
      $package_name = 'iptables-persistent'
      $service_name = 'iptables-persistent'
      $rules_dir = '/etc/iptables'
      $ipv4_rules = '/etc/iptables/rules.v4'
      $ipv6_rules = '/etc/iptables/rules.v6'
      # Because there is no running process for this service, the normal status
      # checks fail.  Because puppet then thinks the service has been manually
      # stopped, it won't restart it.  This fake status command will trick
      # puppet into thinking the service is *always* running (which in a way
      # it is, as iptables is part of the kernel.)
      $service_has_status = true
      $service_status_cmd = true
      # Under Debian, the "restart" parameter does not reload the rules, so
      # tell Puppet to fall back to stop/start, which does work.
      $service_has_restart = false
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'iptables' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
