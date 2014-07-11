# Class: iptables::params
#
# This class holds parameters that need to be
# accessed by other classes.
class iptables::params {
  case $::osfamily {
    'RedHat': {
      if $::operatingsystem == RedHat and $::operatingsystemrelease >= 7 or
        $::operatingsystem == Fedora and $::operatingsystemrelease >= 15 {
        $package_name = 'iptables-services'
        $service_has_restart = true
      }
      else {
        $package_name = 'iptables'
        $service_has_restart = false
      }
      $service_name = 'iptables'
      $rules_dir = '/etc/sysconfig'
      $ipv4_rules = '/etc/sysconfig/iptables'
      $ipv6_rules = '/etc/sysconfig/ip6tables'
      $service_has_status = true
      $service_status_cmd = undef
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
