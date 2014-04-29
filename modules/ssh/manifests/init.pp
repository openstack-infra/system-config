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
      source  => [
        "puppet:///modules/ssh/sshd_config.${::osfamily}",
        'puppet:///modules/ssh/sshd_config',
      ],
      replace => true,
    }
}
