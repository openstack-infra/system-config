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
    $::openstack_project::jenkins_params::docbook_xml_package, # for building openstack docs
    $::openstack_project::jenkins_params::docbook5_xml_package, # for building openstack docs
    $::openstack_project::jenkins_params::docbook5_xsl_package, # for building openstack docs
    $::openstack_project::jenkins_params::gettext_package, # for msgfmt, used in translating manuals
    $::openstack_project::jenkins_params::gnome_doc_package, # for generating translation files for docs
    $::openstack_project::jenkins_params::graphviz_package, # for generating graphs in docs
    $::openstack_project::jenkins_params::firefox_package, # for selenium tests
    $::openstack_project::jenkins_params::language_fonts_packages,
    $::openstack_project::jenkins_params::libcurl_dev_package,
    $::openstack_project::jenkins_params::libevent_dev_package, # for gevent egg
    $::openstack_project::jenkins_params::libpcap_dev_package, # for pypcap egg
    $::openstack_project::jenkins_params::ldap_dev_package,
    $::openstack_project::jenkins_params::librrd_dev_package, # for python-rrdtool, used by kwapi
    $::openstack_project::jenkins_params::libsasl_dev, # for keystone ldap auth integration
    $::openstack_project::jenkins_params::memcached_package, # for tooz unit tests
    $::openstack_project::jenkins_params::redis_package, # for tooz unit tests (and others that use redis)
    $::openstack_project::jenkins_params::mongodb_package, # for ceilometer unit tests
    $::openstack_project::jenkins_params::mysql_dev_package,
    $::openstack_project::jenkins_params::sqlite_dev_package,
    $::openstack_project::jenkins_params::libvirt_dev_package,
    $::openstack_project::jenkins_params::libxml2_package,
    $::openstack_project::jenkins_params::libxml2_dev_package, # for xmllint, need for wadl
    $::openstack_project::jenkins_params::libxslt_dev_package,
    $::openstack_project::jenkins_params::libffi_dev_package, # xattr's cffi dependency
    $::openstack_project::jenkins_params::pkgconfig_package, # for spidermonkey, used by ceilometer
    $::openstack_project::jenkins_params::python_libvirt_package,
    $::openstack_project::jenkins_params::python_lxml_package, # for validating openstack manuals
    $::openstack_project::jenkins_params::python_zmq_package, # zeromq unittests (not pip installable)
    $::openstack_project::jenkins_params::rubygems_package,
    $::openstack_project::jenkins_params::sqlite_package,
    $::openstack_project::jenkins_params::unzip_package,
    $::openstack_project::jenkins_params::zip_package,
    $::openstack_project::jenkins_params::xslt_package, # for building openstack docs
    $::openstack_project::jenkins_params::xvfb_package, # for selenium tests
    $::openstack_project::jenkins_params::php5_cli_package, # for community portal build

    $::openstack_project::jenkins_params::uuid_dev, # for oslo.messaging pyngus/proton
    $::openstack_project::jenkins_params::swig, # for oslo.messaging pyngus/proton
    $::openstack_project::jenkins_params::libjpeg_dev, # for sphinx Pillow dep
    $::openstack_project::jenkins_params::zlib_dev, # for sphinx Pillow dep
  ]

  package { $packages:
    ensure => present,
  }

  include pip
  # for pushing files to swift and uploading to pypi with twine
  package { 'requests':
    ensure   => latest,
    provider => openstack_pip,
  }
  if ($::osfamily == 'RedHat') {
    # Work around https://bugzilla.redhat.com/show_bug.cgi?id=973375
    exec { 'remove_requests':
      command => "/usr/bin/yum remove -y ${::openstack_project::jenkins_params::python_requests_package}",
      onlyif  => "/bin/rpm -qa|/bin/grep -q ${::openstack_project::jenkins_params::python_requests_package}",
      before  => Package['requests'],
    }
  } else {
    package { $::openstack_project::jenkins_params::python_requests_package:
      ensure => absent,
      before => Package['requests'],
    }
  }

  if ($::lsbdistcodename == 'trusty') {

    # Only install PyPy and Python 3.4 packages on Ubuntu 14.04 LTS (Trusty)
    package { $::openstack_project::jenkins_params::pypy_dev_package:
      ensure => present,
    }
    package { $::openstack_project::jenkins_params::pypy_package:
      ensure => present,
    }
    package { $::openstack_project::jenkins_params::python3_dev_package:
      ensure => present,
    }
    package { $::openstack_project::jenkins_params::python3_package:
      ensure => present,
    }

    # for pyeclib, used by swift, not available before Trusty
    package { $::openstack_project::jenkins_params::libjerasure_dev_package:
      ensure => present,
    }

    # Don't install the Ruby Gems profile script on Trusty
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

  case $::osfamily {
    'RedHat': {
      if ($::operatingsystem == 'Fedora') {
        # For [tooz, taskflow, nova] using zookeeper in unit tests
        package { $::openstack_project::jenkins_params::zookeeper_package:
            ensure => present,
        }

        # Fedora needs community-mysql package for mysql_config
        # command used in some gate-{project}-python27
        # jobs in Jenkins
        package { $::openstack_project::jenkins_params::mysql_package:
            ensure => present,
        }
        if ($::operatingsystemrelease >= 22) {
          # For pyeclib, used by swift
          package { $::openstack_project::jenkins_params::liberasurecode_dev_package:
            ensure => present,
          }
        }
      }
      elsif ($::operatingsystem == 'CentOS') {
        if ($::operatingsystemmajrelease >= '7') {
          # For pyeclib, used by swift
          package { $::openstack_project::jenkins_params::liberasurecode_dev_package:
            ensure => present,
          }
        }
      }
    }
    'Debian': {
      # For [tooz, taskflow, nova] using zookeeper in unit tests
      package { $::openstack_project::jenkins_params::zookeeper_package:
        ensure => present,
      }

      # For openstackid using php5-mcrypt for distro build
      package { $::openstack_project::jenkins_params::php5_mcrypt_package:
        ensure => present,
      }

      # For pyeclib, used by swift
      package { $::openstack_project::jenkins_params::liberasurecode_dev_package:
        ensure => present,
      }
    }
  }
  package { 'rake':
    ensure   => '10.1.1',
    provider => gem,
    before   => Package['puppetlabs_spec_helper'],
    require  => Package[$::openstack_project::jenkins_params::rubygems_package],
  }

  package { 'puppet-lint':
    ensure   => '0.3.2',
    provider => gem,
    require  => Package[$::openstack_project::jenkins_params::rubygems_package],
  }

  $gem_packages = [
    'bundler',
    'puppetlabs_spec_helper',
  ]

  package { $gem_packages:
    ensure   => latest,
    provider => gem,
    require  => Package[$::openstack_project::jenkins_params::rubygems_package],
  }

  if ($::in_chroot) {
    notify { 'databases in chroot':
      message => 'databases and grants not created, running in chroot',
    }
  } else {
    class { 'openstack_project::slave_db':
      all_mysql_privs => $all_mysql_privs,
    }
  }
}
# vim:sw=2:ts=2:expandtab:textwidth=79
