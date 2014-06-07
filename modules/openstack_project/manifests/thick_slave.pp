# Extra configuration (like mysql) that we will want on many but not all
# slaves.
class openstack_project::thick_slave(
  $all_mysql_privs = false,
){

  include openstack_project::jenkins_params

  # Packages that most jenkins slaves (eg, unit test runners) need
  $packages = [
    $::openstack_project::jenkins_params::ant_package, # for building buck
    $::openstack_project::jenkins_params::awk_package, # for building extract_docs.awk to work correctly
    $::openstack_project::jenkins_params::asciidoc_package, # for building gerrit/building openstack docs
    $::openstack_project::jenkins_params::curl_package,
    $::openstack_project::jenkins_params::docbook_xml_package, # for building openstack docs
    $::openstack_project::jenkins_params::docbook5_xml_package, # for building openstack docs
    $::openstack_project::jenkins_params::docbook5_xsl_package, # for building openstack docs
    $::openstack_project::jenkins_params::gettext_package, # for msgfmt, used in translating manuals
    $::openstack_project::jenkins_params::gnome_doc_package, # for generating translation files for docs
    $::openstack_project::jenkins_params::graphviz_package, # for generating graphs in docs
    $::openstack_project::jenkins_params::firefox_package, # for selenium tests
    $::openstack_project::jenkins_params::mod_wsgi_package,
    $::openstack_project::jenkins_params::language_fonts_packages,
    $::openstack_project::jenkins_params::libcurl_dev_package,
    $::openstack_project::jenkins_params::ldap_dev_package,
    $::openstack_project::jenkins_params::librrd_dev_package, # for python-rrdtool, used by kwapi
    $::openstack_project::jenkins_params::libtidy_package, # for python-tidy, used by sphinxcontrib-docbookrestapi
    $::openstack_project::jenkins_params::libsasl_dev, # for keystone ldap auth integration
    $::openstack_project::jenkins_params::memcached_package, # for tooz unit tests
    $::openstack_project::jenkins_params::mongodb_package, # for ceilometer unit tests
    $::openstack_project::jenkins_params::mysql_dev_package,
    $::openstack_project::jenkins_params::nspr_dev_package, # for spidermonkey, used by ceilometer
    $::openstack_project::jenkins_params::sqlite_dev_package,
    $::openstack_project::jenkins_params::libvirt_dev_package,
    $::openstack_project::jenkins_params::libxml2_package,
    $::openstack_project::jenkins_params::libxml2_dev_package, # for xmllint, need for wadl
    $::openstack_project::jenkins_params::libxslt_dev_package,
    $::openstack_project::jenkins_params::libffi_dev_package, # xattr's cffi dependency
    $::openstack_project::jenkins_params::pandoc_package, #for docs, markdown->docbook, bug 924507
    $::openstack_project::jenkins_params::pkgconfig_package, # for spidermonkey, used by ceilometer
    $::openstack_project::jenkins_params::python_libvirt_package,
    $::openstack_project::jenkins_params::python_lxml_package, # for validating openstack manuals
    $::openstack_project::jenkins_params::python_magic_package, # for pushing files to swift
    $::openstack_project::jenkins_params::python_zmq_package, # zeromq unittests (not pip installable)
    $::openstack_project::jenkins_params::rubygems_package,
    $::openstack_project::jenkins_params::sbcl_package, # cl-openstack-client testing
    $::openstack_project::jenkins_params::sqlite_package,
    $::openstack_project::jenkins_params::unzip_package,
    $::openstack_project::jenkins_params::zip_package,
    $::openstack_project::jenkins_params::xslt_package, # for building openstack docs
    $::openstack_project::jenkins_params::xvfb_package, # for selenium tests
    $::openstack_project::jenkins_params::php5_cli_package, # for community portal build
  ]

  package { $packages:
    ensure => present,
  }

  include pip
  # for pushing files to swift and uploading to pypi with twine
  package { 'requests':
    ensure   => latest,
    provider => pip,
  }
  # transitional for upgrading to the pip version
  package { $::openstack_project::jenkins_params::python_requests_package:
    ensure => absent,
    before => Package['requests'],
  }

  if ($::lsbdistcodename == 'trusty') {
    file { '/etc/profile.d/rubygems.sh':
      ensure => absent,
    }
  } else {
    file { '/etc/profile.d/rubygems.sh':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/openstack_project/rubygems.sh',
    }
  }

  package { 'rake':
    ensure   => '10.1.1',
    provider => gem,
    before   => Package['puppetlabs_spec_helper'],
    require  => Package[$::openstack_project::jenkins_params::rubygems_package],
  }

  $gem_packages = [
    'bundler',
    'puppet-lint',
    'puppetlabs_spec_helper',
  ]

  package { $gem_packages:
    ensure   => latest,
    provider => gem,
    require  => Package[$::openstack_project::jenkins_params::rubygems_package],
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

  if ($::lsbdistcodename == 'trusty') {
    class { 'postgresql::globals':
      version => '9.3',
      before  => Class['postgresql::server'],
    }
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

  if ($::in_chroot) {
    notify { 'databases in chroot':
      message => 'databases and grants not created, running in chroot',
    }
  } else {
    class { 'openstack_project::slave_db':
      all_mysql_privs => $all_mysql_privs,
      require => [
        Class['postgresql::server'],
        Class['mysql::server'],
      ]
    }
  }

}
# vim:sw=2:ts=2:expandtab:textwidth=79
