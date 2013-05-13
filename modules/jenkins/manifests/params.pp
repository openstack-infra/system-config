# Class: jenkins::params
#
# This class holds parameters that need to be
# accessed by other classes.
class jenkins::params {
  case $::osfamily {
    'RedHat': {
      $common_packages = [
        'java-1.7.0-openjdk',
        'ccache',
        'python-netaddr'
      ]
      $slave_packages = [
        'asciidoc', # for building gerrit/building openstack docs
        'curl',
        'docbook-style-xsl', # for building openstack docs
        'docbook5-schemas', # for building openstack docs
        'docbook5-style-xsl', # for building openstack docs
        'firefox', # for selenium tests
        'mod_wsgi',
        'libcurl-devel',
        'openldap-devel', # for keystone ldap auth integration
        'cyrus-sasl-devel',
        'mysql-devel',
        'nspr-devel', # for spidermonkey, used by ceilometer
        'sqlite-devel',
        'libxml2',
        'libxml2-devel', # for xmllint, need for wadl
        'libxslt-devel',
        # FIXME: No Maven packages on RHEL
        #$maven_package = 'maven'
        'pandoc', # for docs, markdown->docbook, bug 924507
        'pkgconfig', # for spidermonkey, used by ceilometer
        'pyflakes',
        'libvirt-python',
        'python-lxml', # for validating openstack manuals
        'python-zmq', # zeromq unittests (not pip installable)
        # FIXME: No Python3 packages on RHEL
        #$python3_dev_package = 'python3-devel'
        'rubygems',
        'sqlite',
        'unzip',
        'libxslt', # for building openstack docs
        'xorg-x11-server-Xvfb' # for selenium tests
      ]
      $cgroups_package = 'libcgroup'
      $cgconfig_require = Package['cgroups']
      $cgred_require = Package['cgroups']
    }
    'Debian': {
      $common_packages = [
        'default-jdk',
        'ccache',
        'python-netaddr'
      ]
      $slave_packages = [
        'asciidoc', # for building gerrit/building openstack docs
        'build-essential',
        'curl',
        'docbook-xml', # for building openstack docs
        'docbook5-xml', # for building openstack docs
        'docbook-xsl', # for building openstack docs
        'firefox', # for selenium tests
        'libapache2-mod-wsgi',
        'libcurl4-gnutls-dev',
        'libldap2-dev',
        'libsasl2-dev', # for keystone ldap auth integration
        'libmysqlclient-dev',
        'libnspr4-dev', # for spidermonkey, used by ceilometer
        'libsqlite3-dev',
        'libxml2-utils',
        'libxml2-dev', # for xmllint, need for wadl
        'libxslt1-dev',
        'maven2'
        'pandoc', # for docs, markdown->docbook, bug 924507
        'pkg-config', # for spidermonkey, used by ceilometer
        'pyflakes',
        'python3-all-dev',
        'python-libvirt',
        'python-lxml', # for validating openstack manuals
        'python-zmq', # zeromq unittests (not pip installable)
        'rubygems',
        'ruby1.9.1',
        'ruby1.9.1-dev',
        'ruby-bundler',
        'sqlite3',
        'unzip',
        'xsltproc', # for building openstack docs
        'xvfb' # for selenium tests
      ]
      $cgroups_package = 'cgroup-bin'
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
