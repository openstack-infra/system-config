import "jenkins_slave"

class doc_server {

  include jenkins_slave

  package { 'nginx':
    ensure => present;
  }

  package { "python-storm":
    ensure => present
  }

  package { "python-mako":
    ensure => present
  }

  package { "python-pychart":
    ensure => present
  }

  package { "planet-venus":
    ensure => present
  }
  
  doc_server::site { "burrow": }

  doc_server::site { "ci": }

  doc_server::site { "keystone": }

  doc_server::site { "glance": }

  doc_server::site { "nova": }

  doc_server::site { "swift": }
}
