# Class: jenkins::params
#
# This class holds parameters that need to be
# accessed by other classes.
class jenkins::params {
  case $::osfamily {
    'RedHat': {
      #yum groupinstall "Development Tools"
      # common packages
      if ($::operatingsystem == 'Fedora') and ($::operatingsystemrelease >= 21) {
        $jdk_package = 'java-1.8.0-openjdk-devel'
      } else {
        $jdk_package = 'java-1.7.0-openjdk-devel'
      }
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      # FIXME: No Maven packages on RHEL
      #$maven_package = 'maven'
      $cgroups_package = 'libcgroup'
      if ($::operatingsystem == 'Fedora') and ($::operatingsystemrelease >= 19) {
        $cgroups_tools_package = 'libcgroup-tools'
        $cgconfig_require = [
          Package['cgroups'],
          Package['cgroups-tools'],
        ]
        $cgred_require = [
          Package['cgroups'],
          Package['cgroups-tools'],
        ]
      } else {
        $cgroups_tools_package = ''
        $cgconfig_require = Package['cgroups']
        $cgred_require = Package['cgroups']
      }
    }
    'Debian': {
      # common packages
      $jdk_package = 'openjdk-7-jdk'
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      $maven_package = 'maven2'
      $ruby1_9_1_package = 'ruby1.9.1'
      $ruby1_9_1_dev_package = 'ruby1.9.1-dev'
      $cgroups_package = 'cgroup-bin'
      $cgroups_tools_package = ''
      $cgconfig_require = [
        Package['cgroups'],
        File['/etc/init/cgconfig.conf'],
      ]
      $cgred_require = [
        Package['cgroups'],
        File['/etc/init/cgred.conf'],
      ]
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'jenkins' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
