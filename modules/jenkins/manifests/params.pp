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
      # FIXME: No php mcrypt package on RHEL, used for openstackid
      #$php5_mcrypt_package = ''
      # For Tooz unit tests
      # FIXME: No zookeeper packages on RHEL
      #$zookeeper_package = 'zookeeper-server'
      $cgroups_package = 'libcgroup'
      if ($::operatingsystem == 'Fedora') and ($::operatingsystemrelease >= 19) {
        # From Fedora 19 and onwards there's no longer
        # support to mysql-devel.
        # Only community-mysql-devel. If you try to
        # install mysql-devel you get a conflict with
        # mariadb packages.
        $mysql_dev_package = 'community-mysql-devel'
        $zookeeper_package = 'zookeeper'
        $mysql_package = 'community-mysql'
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
        $mysql_dev_package = 'mysql-devel'
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
      # For tooz unit tests
      $memcached_package = 'memcached'
      $ruby1_9_1_package = 'ruby1.9.1'
      $ruby1_9_1_dev_package = 'ruby1.9.1-dev'
      $ruby_bundler_package = 'ruby-bundler'
      $php5_mcrypt_package = 'php5-mcrypt'
      # For [tooz, taskflow, nova] using zookeeper in unit tests
      $zookeeper_package = 'zookeeperd'
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
