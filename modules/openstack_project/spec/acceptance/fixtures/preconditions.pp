if $::operatingsystem == 'CentOS' {
  package { 'epel-release':
    ensure => present,
  }
}
