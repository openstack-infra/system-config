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

  if ($bare == false) {
    $packages = [
      $::jenkins::params::common_packages,
      $::jenkins::params::standard_packages
    ]
  } else {
    $packages = $::jenkins::params::common_packages
  }

  package { $packages:
    ensure => present,
  }

  case $::osfamily {
    'RedHat': {

      exec { 'yum Group Install':
        unless  => '/usr/bin/yum grouplist "Development tools" | /bin/grep "^Installed Groups"',
        command => '/usr/bin/yum -y groupinstall "Development tools"',
      }

    }
    'Debian': {

    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'jenkins' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }

  if ($bare == false) {
    $gem_packages = [
      'bundler',
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

    # mysql::db is too dumb to realize that the same user can have
    # access to multiple databases and will fail if you try creating
    # a second DB with the same user. Create the DB directly as mysql::db
    # above is creating the user for us.
    database { 'openstack_baremetal_citest':
      ensure   => present,
      charset  => 'utf8',
      provider => 'mysql',
      require  => [
        Class['mysql::server'],
        Class['mysql::server::account_security'],
      ],
    }

    database_grant { 'openstack_citest@localhost/openstack_baremetal_citest':
      privileges => ['all'],
      provider   => 'mysql',
      require    => Database_user['openstack_citest@localhost'],
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

    # Create DB user and explicitly make it non superuser
    # that can create databases.
    postgresql::database_user { 'openstack_citest':
      password_hash => 'openstack_citest',
      createdb      => true,
      superuser     => false,
      require       => Class['postgresql::server'],
    }

    postgresql::db { 'openstack_citest':
      user     => 'openstack_citest',
      password => 'openstack_citest',
      grant    => 'all',
      require  => [
        Class['postgresql::server'],
        Postgresql::Database_user['openstack_citest'],
      ],
    }

    # Alter the new database giving the test DB user ownership of the DB.
    # This is necessary to make the nova unittests run properly.
    postgresql_psql { 'ALTER DATABASE openstack_citest OWNER TO openstack_citest':
      db          => 'postgres',
      refreshonly => true,
      subscribe   => Postgresql::Db['openstack_citest'],
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
  if ($::osfamily == 'Debian') {

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

  file { '/etc/rsyslog.d/99-maxsize.conf':
    ensure => absent,
  }
}
