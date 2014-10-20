# Install and run haveged to provide entropy
class haveged {

  package { 'haveged':
    ensure => present,
  }

  service { 'haveged':
    enable  => true,
    require => Package[haveged],
  }

}
