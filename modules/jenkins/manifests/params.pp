# Class: jenkins::params
#
# This class holds parameters that need to be
# accessed by other classes.
class jenkins::params {
  case $::osfamily {
    'RedHat': {
      #yum groupinstall "Development Tools"
      # common packages
      $jdk_package = 'java-1.7.0-openjdk-devel'
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      $haveged_package = 'haveged'
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
      $haveged_package = 'haveged'
      $maven_package = 'maven2'
      $maven_settings_file_path = $maven_package ? {
        'maven'  => '/etc/maven/settings.xml',
        'maven2' => '/etc/maven2/settings.xml',
      }
      # For tooz unit tests
      $memcached_package = 'memcached'
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
