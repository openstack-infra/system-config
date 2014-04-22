# == Class: jenkins::slave
#
class jenkins::slave(
  $ssh_key = '',
  $sudo = false,
  $user = true,
  $python3 = false,
) {

  include pip
  include jenkins::params

  if ($user == true) {
    class { 'jenkins::jenkinsuser':
      ensure  => present,
      ssh_key => $ssh_key,
    }
  }

  anchor { 'jenkins::slave::update-java-alternatives': }

  # Packages that all jenkins slaves need
  $packages = [
    $::jenkins::params::jdk_package, # jdk for building java jobs
    $::jenkins::params::ccache_package,
    $::jenkins::params::python_netaddr_package, # Needed for devstack address_in_net()
    $::jenkins::params::haveged_package, # entropy is useful to have
  ]

  file { '/etc/apt/sources.list.d/cloudarchive.list':
    ensure => absent,
  }

  package { $packages:
    ensure => present,
    before => Anchor['jenkins::slave::update-java-alternatives']
  }

  case $::osfamily {
    'RedHat': {

      exec { 'yum Group Install':
        unless  => '/usr/bin/yum grouplist "Development tools" | /bin/grep "^Installed Groups"',
        command => '/usr/bin/yum -y groupinstall "Development tools"',
      }

      if ($::operatingsystem == 'Fedora') {
          package { $::jenkins::params::zookeeper_package:
              ensure => present,
          }
          # Fedora needs community-mysql package for mysql_config
          # command used in some gate-{project}-python27
          # jobs in Jenkins
          package { $::jenkins::params::mysql_package:
              ensure => present,
          }
      } else {
          exec { 'update-java-alternatives':
            unless   => '/bin/ls -l /etc/alternatives/java | /bin/grep 1.7.0-openjdk',
            command  => '/usr/sbin/alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java && /usr/sbin/alternatives --set javac /usr/lib/jvm/java-1.7.0-openjdk.x86_64/bin/javac',
            require  => Anchor['jenkins::slave::update-java-alternatives']
          }
      }
    }
    'Debian': {

      # install build-essential package group
      package { 'build-essential':
        ensure => present,
      }

      package { $::jenkins::params::maven_package:
        ensure  => present,
        require => Package[$::jenkins::params::jdk_package],
      }

      package { $::jenkins::params::ruby1_9_1_package:
        ensure => present,
      }

      package { $::jenkins::params::ruby1_9_1_dev_package:
        ensure => present,
      }

      package { $::jenkins::params::ruby_bundler_package:
        ensure => present,
      }

      package { 'openjdk-6-jre-headless':
        ensure  => purged,
        require => Package[$::jenkins::params::jdk_package],
      }

      # For [tooz, taskflow, nova] using zookeeper in unit tests
      package { $::jenkins::params::zookeeper_package:
        ensure => present,
      }

      # For openstackid using php5-mcrypt for distro build
      package { $::jenkins::params::php5_mcrypt_package:
        ensure => present,
      }

      exec { 'update-java-alternatives':
        unless   => '/bin/ls -l /etc/alternatives/java | /bin/grep java-7-openjdk-amd64',
        command  => '/usr/sbin/update-java-alternatives --set java-1.7.0-openjdk-amd64',
        require  => Anchor['jenkins::slave::update-java-alternatives']
      }

    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'jenkins' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }

  # Packages that need to be installed from pip
  # Temporarily removed tox so we can pin it separately (see below)
  $pip_packages = [
    'setuptools-git',
  ]

  if $python3 {
    if ($::lsbdistcodename == 'precise') {
      apt::ppa { 'ppa:zulcss/py3k':
        before => Class[pip::python3],
      }
    }
    include pip::python3
    package { $pip_packages:
      ensure   => latest,  # we want the latest from these
      provider => pip3,
      require  => Class[pip::python3],
    }
    # Temporarily handle tox separately so we can pin it
    package { 'tox':
      ensure   => '1.6.1',
      provider => pip3,
      require  => Class['pip::python3'],
    }
  } else {
    package { $pip_packages:
      ensure   => latest,  # we want the latest from these
      provider => pip,
      require  => Class[pip],
    }
    # Temporarily handle tox separately so we can pin it
    package { 'tox':
      ensure   => '1.6.1',
      provider => pip,
      require  => Class['pip'],
    }
  }

  package { 'python-subunit':
    ensure   => absent,
    provider => pip,
    require  => Class[pip],
  }

  package { 'git-review':
    ensure   => '1.17',
    provider => pip,
    require  => Class[pip],
  }

  file { '/etc/profile.d/rubygems.sh':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/jenkins/rubygems.sh',
  }

  file { '/usr/local/bin/gcc':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/bin/g++':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/bin/cc':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/bin/c++':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/jenkins':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if ($sudo == true) {
    file { '/etc/sudoers.d/jenkins-sudo':
      ensure => present,
      source => 'puppet:///modules/jenkins/jenkins-sudo.sudo',
      owner  => 'root',
      group  => 'root',
      mode   => '0440',
    }
  }

  file { '/etc/sudoers.d/jenkins-sudo-grep':
    ensure => present,
    source => 'puppet:///modules/jenkins/jenkins-sudo-grep.sudo',
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
  }
}
