# == Class: jenkins::slave
#
class jenkins::slave(
  $ssh_key = '',
  $sudo = false,
  $bare = false,
  $user = true,
) {

  include pip
  include jenkins::params

  if ($user == true) {
    class { 'jenkins::jenkinsuser':
      ensure  => present,
      sudo    => $sudo,
      ssh_key => $ssh_key,
    }
  }

  # Packages that all jenkins slaves need
  $common_packages = [
    $::jenkins::params::jdk_package, # jdk for building java jobs
    $::jenkins::params::ccache_package,
    $::jenkins::params::python_netaddr_package, # Needed for devstack address_in_net()
  ]

  # Packages that most jenkins slaves (eg, unit test runners) need
  $standard_packages = [
    $::jenkins::params::asciidoc_package, # for building gerrit/building openstack docs
    $::jenkins::params::curl_package,
    $::jenkins::params::docbook_xml_package, # for building openstack docs
    $::jenkins::params::docbook5_xml_package, # for building openstack docs
    $::jenkins::params::docbook5_xsl_package, # for building openstack docs
    $::jenkins::params::firefox_package, # for selenium tests
    $::jenkins::params::mod_wsgi_package,
    $::jenkins::params::libcurl_dev_package,
    $::jenkins::params::ldap_dev_package,
    $::jenkins::params::librrd_dev_package, # for py-rrdtool, used by kwapi
    $::jenkins::params::libsasl_dev, # for keystone ldap auth integration
    $::jenkins::params::mysql_dev_package,
    $::jenkins::params::nspr_dev_package, # for spidermonkey, used by ceilometer
    $::jenkins::params::sqlite_dev_package,
    $::jenkins::params::libxml2_package,
    $::jenkins::params::libxml2_dev_package, # for xmllint, need for wadl
    $::jenkins::params::libxslt_dev_package,
    $::jenkins::params::pandoc_package, #for docs, markdown->docbook, bug 924507
    $::jenkins::params::pkgconfig_package, # for spidermonkey, used by ceilometer
    $::jenkins::params::pyflakes_package,
    $::jenkins::params::python_libvirt_package,
    $::jenkins::params::python_zmq_package, # zeromq unittests (not pip installable)
    $::jenkins::params::rubygems_package,
    $::jenkins::params::sqlite_package,
    $::jenkins::params::unzip_package,
    $::jenkins::params::xslt_package, # for building openstack docs
    $::jenkins::params::xvfb_package, # for selenium tests
  ]

  if ($bare == false) {
    $packages = [$common_packages, $standard_packages]
  } else {
    $packages = $common_packages
  }

  package { $packages:
    ensure => present,
  }

  if ($::operatingsystem == 'Redhat') {

    exec { 'yum Group Install':
      unless  => '/usr/bin/yum grouplist "Development tools" | /bin/grep "^Installed Groups"',
      command => '/usr/bin/yum -y groupinstall "Development tools"',
    }

  }
  if ($::operatingsystem == 'Ubuntu') {

    # install build-essential package group
    package { 'build-essential':
      ensure => present,
    }

    package { $::jenkins::params::maven_package:
      ensure => present,
    }

    package { $::jenkins::params::python3_dev_package:
      ensure => present,
    }

  }

  if ($bare == false) {
    $gem_packages = [
      'puppet-lint',
      'puppetlabs_spec_helper',
    ]

    package { $gem_packages:
      ensure   => latest,
      provider => gem,
      require  => Package['rubygems'],
    }
  }

  # Packages that need to be installed from pip
  $pip_packages = [
    'python-subunit',
    'setuptools-git',
    'tox',
  ]

  package { $pip_packages:
    ensure   => latest,  # we want the latest from these
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

  if ($bare == false) {
    class {'mysql::server':
      config_hash =>  {
        'root_password'  => 'insecure_slave',
        'default_engine' => 'MyISAM',
        'bind_address'   => '127.0.0.1',
      }
    }
    include mysql::server::account_security

    mysql::db { 'openstack_citest':
      user     => 'openstack_citest',
      password => 'openstack_citest',
      host     => 'localhost',
      grant    => ['all'],
      require  => [
        Class['mysql::server'],
        Class['mysql::server::account_security'],
      ],
    }

    $no_postgresql_version = 'Unsupported OS!  Please check `postgres_default_version` fact.'
    if $::postgres_default_version == $no_postgresql_version {
      # Have a default postgres version if the postgresql module can't decide
      # on a sane default for itself.
      $postgresql_version = '9.1'
    }
    else {
      $postgresql_version = $::postgres_default_version
    }
    class { 'postgresql::params':
      version => $postgresql_version,
    }

    class { 'postgresql::server':
      config_hash => {
        'postgres_password'      => 'insecure_slave',
        'manage_redhat_firewall' => false,
        'listen_addresses'       => '127.0.0.1',
      },
      require     => Class['postgresql::params'],
    }

    class { 'postgresql::devel':
      require => Class['postgresql::params'],
    }

    postgresql::db { 'openstack_citest':
      user     => 'openstack_citest',
      password => 'openstack_citest',
      grant    => 'all',
      require  => Class['postgresql::server'],
    }

    postgresql::database_grant { 'grant_openstack_citest_privs':
      privilege => 'ALL',
      db        => 'openstack_citest',
      role      => 'openstack_citest',
      require   => Postgresql::Db['openstack_citest'],
    }
  }

  file { '/usr/local/jenkins':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/jenkins/slave_scripts':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    require => File['/usr/local/jenkins'],
    source  => 'puppet:///modules/jenkins/slave_scripts',
  }

  file { '/etc/sudoers.d/jenkins-sudo-grep':
    ensure => present,
    source => 'puppet:///modules/jenkins/jenkins-sudo-grep.sudo',
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
  }

  # Temporary for debugging glance launch problem
  # https://lists.launchpad.net/openstack/msg13381.html
  # NOTE(dprince): ubuntu only as RHEL6 doesn't have sysctl.d yet
  if ($::operatingsystem == 'Ubuntu') {

    file { '/etc/sysctl.d/10-ptrace.conf':
      ensure => present,
      source => 'puppet:///modules/jenkins/10-ptrace.conf',
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
    }

    exec { 'ptrace sysctl':
      subscribe   => File['/etc/sysctl.d/10-ptrace.conf'],
      refreshonly => true,
      command     => '/sbin/sysctl -p /etc/sysctl.d/10-ptrace.conf',
    }

  }

}
