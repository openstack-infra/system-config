class ssh {
    package { openssh-server: ensure => present }
    service { ssh:
      ensure          => running,
      hasrestart      => true,
      subscribe       => File["/etc/ssh/sshd_config"],
    }
    file { "/etc/ssh/sshd_config":
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source => [
                 "puppet:///modules/ssh/sshd_config.$operatingsystem",
                 "puppet:///modules/ssh/sshd_config"
      ],
      replace => 'true',
    }
}
