# == Class: jenkins::slave
#
class jenkins::unittest_slave {

  include pip
  include jenkins::params

  # Packages that most jenkins slaves (eg, unit test runners) need
  $packages = [
    $::jenkins::params::ant_package, # for building buck
    $::jenkins::params::awk_package, # for building extract_docs.awk to work correctly
    $::jenkins::params::asciidoc_package, # for building gerrit/building openstack docs
    $::jenkins::params::curl_package,
    $::jenkins::params::docbook_xml_package, # for building openstack docs
    $::jenkins::params::docbook5_xml_package, # for building openstack docs
    $::jenkins::params::docbook5_xsl_package, # for building openstack docs
    $::jenkins::params::gettext_package, # for msgfmt, used in translating manuals
    $::jenkins::params::gnome_doc_package, # for generating translation files for docs
    $::jenkins::params::graphviz_package, # for generating graphs in docs
    $::jenkins::params::firefox_package, # for selenium tests
    $::jenkins::params::mod_wsgi_package,
    $::jenkins::params::language_fonts_packages,
    $::jenkins::params::libcurl_dev_package,
    $::jenkins::params::ldap_dev_package,
    $::jenkins::params::librrd_dev_package, # for python-rrdtool, used by kwapi
    $::jenkins::params::libtidy_package, # for python-tidy, used by sphinxcontrib-docbookrestapi
    $::jenkins::params::libsasl_dev, # for keystone ldap auth integration
    $::jenkins::params::memcached_package, # for tooz unit tests
    $::jenkins::params::mongodb_package, # for ceilometer unit tests
    $::jenkins::params::mysql_dev_package,
    $::jenkins::params::nspr_dev_package, # for spidermonkey, used by ceilometer
    $::jenkins::params::sqlite_dev_package,
    $::jenkins::params::libvirt_dev_package,
    $::jenkins::params::libxml2_package,
    $::jenkins::params::libxml2_dev_package, # for xmllint, need for wadl
    $::jenkins::params::libxslt_dev_package,
    $::jenkins::params::libffi_dev_package, # xattr's cffi dependency
    $::jenkins::params::pandoc_package, #for docs, markdown->docbook, bug 924507
    $::jenkins::params::pkgconfig_package, # for spidermonkey, used by ceilometer
    $::jenkins::params::python_libvirt_package,
    $::jenkins::params::python_lxml_package, # for validating openstack manuals
    $::jenkins::params::python_zmq_package, # zeromq unittests (not pip installable)
    $::jenkins::params::rubygems_package,
    $::jenkins::params::sbcl_package, # cl-openstack-client testing
    $::jenkins::params::sqlite_package,
    $::jenkins::params::unzip_package,
    $::jenkins::params::zip_package,
    $::jenkins::params::xslt_package, # for building openstack docs
    $::jenkins::params::xvfb_package, # for selenium tests
    $::jenkins::params::php5_cli_package, # for community portal build
  ]

  package { $packages:
    ensure => present,
    before => Anchor['jenkins::slave::update-java-alternatives']
  }

  # pin to a release of rake which works with ruby 1.8.x
  # before PSH tries to pull in a newer one which isn't
  package { 'rake':
    ensure   => '10.1.1',
    provider => gem,
    before   => Package['puppetlabs_spec_helper'],
    require  => Package['rubygems'],
  }

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

  if ($::operatingsystem == 'Fedora') and ($::operatingsystemrelease >= 19) {
    class {'mysql::server':
      config_hash  =>  {
        'root_password'  => 'insecure_slave',
        'default_engine' => 'MyISAM',
        'bind_address'   => '127.0.0.1',
      },
      package_name => 'community-mysql-server',
    }
  } else {
    class {'mysql::server':
      config_hash =>  {
        'root_password'  => 'insecure_slave',
        'default_engine' => 'MyISAM',
        'bind_address'   => '127.0.0.1',
      }
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

  if ($all_mysql_privs == true) {
    database_grant { 'openstack_citest@localhost':
      privileges => ['all'],
      provider   => 'mysql',
      require    => Database_user['openstack_citest@localhost'],
    }
  }

  # The puppetlabs postgres module does not manage the postgres user
  # and group for us. Create them here to ensure concat can create
  # dirs and files owned by this user and group.
  user { 'postgres':
    ensure  => present,
    gid     => 'postgres',
    system  => true,
    require => Group['postgres'],
  }

  group { 'postgres':
    ensure => present,
    system => true,
  }

  class { 'postgresql::server':
    postgres_password => 'insecure_slave',
    manage_firewall   => false,
    # The puppetlabs postgres module incorrectly quotes ip addresses
    # in the postgres server config. Use localhost instead.
    listen_addresses  => ['localhost'],
    require           => [
      User['postgres'],
      Class['postgresql::params'],
    ],
  }

  class { 'postgresql::lib::devel':
    require => Class['postgresql::params'],
  }

  # Create DB user and explicitly make it non superuser
  # that can create databases.
  postgresql::server::role { 'openstack_citest':
    password_hash => postgresql_password('openstack_citest', 'openstack_citest'),
    createdb      => true,
    superuser     => false,
    require       => Class['postgresql::server'],
  }

  postgresql::server::db { 'openstack_citest':
    user     => 'openstack_citest',
    password => postgresql_password('openstack_citest', 'openstack_citest'),
    grant    => 'all',
    require  => [
      Class['postgresql::server'],
      Postgresql::Server::Role['openstack_citest'],
    ],
  }

  # Alter the new database giving the test DB user ownership of the DB.
  # This is necessary to make the nova unittests run properly.
  postgresql_psql { 'ALTER DATABASE openstack_citest OWNER TO openstack_citest':
    db          => 'postgres',
    refreshonly => true,
    subscribe   => Postgresql::Server::Db['openstack_citest'],
  }

  postgresql::server::db { 'openstack_baremetal_citest':
    user     => 'openstack_citest',
    password => postgresql_password('openstack_citest', 'openstack_citest'),
    grant    => 'all',
    require  => [
      Class['postgresql::server'],
      Postgresql::Server::Role['openstack_citest'],
    ],
  }

  # Alter the new database giving the test DB user ownership of the DB.
  # This is necessary to make the nova unittests run properly.
  postgresql_psql { 'ALTER DATABASE openstack_baremetal_citest OWNER TO
                     openstack_citest':
    db          => 'postgres',
    refreshonly => true,
    subscribe   => Postgresql::Server::Db['openstack_baremetal_citest'],
  }
}
