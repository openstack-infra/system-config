# == Class: ssh
#
class ssh {
    include ssh::params
    package { $::ssh::params::package_name:
      ensure => present,
    }
    service { $::ssh::params::service_name:
      ensure     => running,
      hasrestart => true,
      subscribe  => File['/etc/ssh/sshd_config'],
    }
    file { '/etc/ssh/sshd_config':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('ssh/sshd_config.erb'),
      replace => true,
    }
}
