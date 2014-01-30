# Class: jenkins::params
#
# This class holds parameters that need to be
# accessed by other classes.
class jenkins::params {
  case $::osfamily {
    'RedHat': {
      #yum groupinstall "Development Tools"
      # common packages
      $jdk_package = 'java-1.7.0-openjdk'
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      # packages needed by slaves
      $asciidoc_package = 'asciidoc'
      $curl_package = 'curl'
      $docbook_xml_package = 'docbook-style-xsl'
      $docbook5_xml_package = 'docbook5-schemas'
      $docbook5_xsl_package = 'docbook5-style-xsl'
      $firefox_package = 'firefox'
      $graphviz_package = 'graphviz'
      $mod_wsgi_package = 'mod_wsgi'
      $libcurl_dev_package = 'libcurl-devel'
      $ldap_dev_package = 'openldap-devel'
      $librrd_dev_package = 'rrdtool-devel'
      # packages needed by document translation
      $gnome_doc_package = 'gnome-doc-utils'
      $libtidy_package = 'libtidy'
      # for keystone ldap auth integration
      $libsasl_dev = 'cyrus-sasl-devel'
      $nspr_dev_package = 'nspr-devel'
      $sqlite_dev_package = 'sqlite-devel'
      $libvirt_dev_package = 'libvirt-devel'
      $libxml2_package = 'libxml2'
      $libxml2_dev_package = 'libxml2-devel'
      $libxslt_dev_package = 'libxslt-devel'
      $libffi_dev_package = 'libffi-devel'
      # FIXME: No Maven packages on RHEL
      #$maven_package = 'maven'
      # For Ceilometer unit tests
      $mongodb_package = 'mongodb-server'
      $pandoc_package = 'pandoc'
      $pkgconfig_package = 'pkgconfig'
      $python_libvirt_package = 'libvirt-python'
      $python_lxml_package = 'python-lxml'
      $python_zmq_package = 'python-zmq'
      $rubygems_package = 'rubygems'
      # Common Lisp interpreter, used for cl-openstack-client
      $sbcl_package = 'sbcl'
      $sqlite_package = 'sqlite'
      $unzip_package = 'unzip'
      $xslt_package = 'libxslt'
      $xvfb_package = 'xorg-x11-server-Xvfb'
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
      # packages needed by slaves
      $asciidoc_package = 'asciidoc'
      $curl_package = 'curl'
      $docbook_xml_package = 'docbook-xml'
      $docbook5_xml_package = 'docbook5-xml'
      $docbook5_xsl_package = 'docbook-xsl'
      $firefox_package = 'firefox'
      $graphviz_package = 'graphviz'
      $mod_wsgi_package = 'libapache2-mod-wsgi'
      $libcurl_dev_package = 'libcurl4-gnutls-dev'
      $ldap_dev_package = 'libldap2-dev'
      $librrd_dev_package = 'librrd-dev'
      # packages needed by document translation
      $gnome_doc_package = 'gnome-doc-utils'
      $libtidy_package = 'libtidy-0.99-0'
      # for keystone ldap auth integration
      $libsasl_dev = 'libsasl2-dev'
      $mysql_dev_package = 'libmysqlclient-dev'
      $nspr_dev_package = 'libnspr4-dev'
      $sqlite_dev_package = 'libsqlite3-dev'
      $libvirt_dev_package = 'libvirt-dev'
      $libxml2_package = 'libxml2-utils'
      $libxml2_dev_package = 'libxml2-dev'
      $libxslt_dev_package = 'libxslt1-dev'
      $libffi_dev_package = 'libffi-dev'
      $maven_package = 'maven2'
      # For Ceilometer unit tests
      $mongodb_package = 'mongodb'
      $pandoc_package = 'pandoc'
      $pkgconfig_package = 'pkg-config'
      $python_libvirt_package = 'python-libvirt'
      $python_lxml_package = 'python-lxml'
      $python_zmq_package = 'python-zmq'
      $rubygems_package = 'rubygems'
      $ruby1_9_1_package = 'ruby1.9.1'
      $ruby1_9_1_dev_package = 'ruby1.9.1-dev'
      $ruby_bundler_package = 'ruby-bundler'
      # Common Lisp interpreter, used for cl-openstack-client
      $sbcl_package = 'sbcl'
      $sqlite_package = 'sqlite3'
      $unzip_package = 'unzip'
      $xslt_package = 'xsltproc'
      $xvfb_package = 'xvfb'
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
