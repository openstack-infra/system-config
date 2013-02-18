# Class: jenkins::params
#
# This class holds parameters that need to be
# accessed by other classes.
class jenkins::params {
  case $::osfamily {
    'Redhat': {
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
      $mod_wsgi_package = 'mod_wsgi'
      $libcurl_dev_package = 'libcurl-devel'
      $ldap_dev_package = 'openldap-devel'
      # for keystone ldap auth integration
      $libsasl_dev = 'cyrus-sasl-devel'
      $mysql_dev_package = 'mysql-devel'
      $nspr_dev_package = 'nspr-devel'
      $sqlite_dev_package = 'sqlite-devel'
      $libxml2_package = 'libxml2'
      $libxml2_dev_package = 'libxml2-devel'
      $libxslt_dev_package = 'libxslt-devel'
      # FIXME: No Maven packages on RHEL
      #$maven_package = 'maven'
      $pandoc_package = 'pandoc'
      $pkgconfig_package = 'pkgconfig'
      $pyflakes_package = 'pyflakes'
      $python_libvirt_package = 'libvirt-python'
      $python_lxml_package = 'python-lxml'
      $python_zmq_package = 'python-zmq'
      # FIXME: No Python3 packages on RHEL
      #$python3_dev_package = 'python3-devel'
      $rubygems_package = 'rubygems'
      $sqlite_package = 'sqlite'
      $unzip_package = 'unzip'
      $xslt_package = 'libxslt'
      $xvfb_package = 'xorg-x11-server-Xvfb'
      $cgroups_package = 'libcgroup'
      $cgconfig_require = Package['cgroups']
      $cgred_require = Package['cgroups']
    }
    'Debian', 'Ubuntu': {
      # common packages
      $jdk_package = 'default-jdk'
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      # packages needed by slaves
      $asciidoc_package = 'asciidoc'
      $curl_package = 'curl'
      $docbook_xml_package = 'docbook-xml'
      $docbook5_xml_package = 'docbook5-xml'
      $docbook5_xsl_package = 'docbook-xsl'
      $firefox_package = 'firefox'
      $mod_wsgi_package = 'libapache2-mod-wsgi'
      $libcurl_dev_package = 'libcurl4-gnutls-dev'
      $ldap_dev_package = 'libldap2-dev'
      # for keystone ldap auth integration
      $libsasl_dev = 'libsasl2-dev'
      $mysql_dev_package = 'libmysqlclient-dev'
      $nspr_dev_package = 'libnspr4-dev'
      $sqlite_dev_package = 'libsqlite3-dev'
      $libxml2_package = 'libxml2-utils'
      $libxml2_dev_package = 'libxml2-dev'
      $libxslt_dev_package = 'libxslt1-dev'
      $maven_package = 'maven2'
      $pandoc_package = 'pandoc'
      $pkgconfig_package = 'pkg-config'
      $pyflakes_package = 'pyflakes'
      $python_libvirt_package = 'python-libvirt'
      $python_lxml_package = 'python-lxml'
      $python_zmq_package = 'python-zmq'
      $python3_dev_package = 'python3-all-dev'
      $rubygems_package = 'rubygems'
      $sqlite_package = 'sqlite3'
      $unzip_package = 'unzip'
      $xslt_package = 'xsltproc'
      $xvfb_package = 'xvfb'
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
      fail("Unsupported osfamily: ${::osfamily} The 'jenkins' module only supports osfamily Ubuntu or Redhat(slaves only).")
    }
  }
}
