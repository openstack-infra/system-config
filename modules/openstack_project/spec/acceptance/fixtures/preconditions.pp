if $::operatingsystem == 'CentOS' {
  package { 'epel-release':
    ensure => present,
  }
  file_line { '/etc/yum.repos.d/epel.repo':
    path  => '/etc/yum.repos.d/epel.repo',
    line  => 'enabled=1',
    match => 'enabled=.'
  }
}
