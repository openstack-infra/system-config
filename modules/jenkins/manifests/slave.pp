# == Class: jenkins::slave
#
class jenkins::slave(
  $ssh_key = '',
  $sudo = false,
  $bare = false,
  $user = true,
) {

  include pip

  if ($user == true) {
    class { 'jenkins::jenkinsuser':
      ensure  => present,
      sudo    => $sudo,
      ssh_key => $ssh_key,
    }
  }

  # Packages that all jenkins slaves need
  $common_packages = [
    'default-jdk', # jdk for building java jobs
    'build-essential',
    'ccache',
    'python-netaddr', # Needed for devstack address_in_net()
  ]

  # Packages that most jenkins slaves (eg, unit test runners) need
  $standard_packages = [
    'asciidoc', # for building gerrit/building openstack docs
    'curl',
    'docbook-xml', # for building openstack docs
    'docbook5-xml', # for building openstack docs
    'docbook-xsl', # for building openstack docs
    'firefox', # for selenium tests
    'libapache2-mod-wsgi',
    'libcurl4-gnutls-dev',
    'libldap2-dev',
    'libmysqlclient-dev',
    'libnspr4-dev', # for spidermonkey, used by ceilometer
    'libsqlite3-dev',
    'libxml2-dev',
    'libxml2-utils', # for xmllint, need for wadl
    'libxslt1-dev',
    'maven2',
    'mercurial',
    'pandoc', #for docs, markdown->docbook, bug 924507
    'pkg-config', # for spidermonkey, used by ceilometer
    'pyflakes',
    'python-libvirt',
    'python-subunit', # for subunit2html.py
    'python-zmq', # zeromq unittests (not pip installable)
    'python3-all-dev',
    'rubygems',
    'sqlite3',
    'unzip',
    'xsltproc', # for building openstack docs
    'xvfb', # for selenium tests
  ]

  if ($bare == false) {
    $packages = [$common_packages, $standard_packages]
  } else {
    $packages = $common_packages
  }

  package { $packages:
    ensure => present,
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
