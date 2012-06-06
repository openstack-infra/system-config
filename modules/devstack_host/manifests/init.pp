# A machine ready to run devstack
class devstack_host {

    package { "linux-headers-virtual":
      ensure => present,
    }

    package { "mysql-server":
      ensure => present,
    }

    package { "rabbitmq-server":
      ensure => present,
      require => File['rabbitmq-env.conf'],
    }

    file { "/etc/rabbitmq":
      ensure => "directory",
    }

    file { 'rabbitmq-env.conf':
      name => '/etc/rabbitmq/rabbitmq-env.conf',
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source => [
         "puppet:///modules/devstack_host/rabbitmq-env.conf",
       ],
      require => File['/etc/rabbitmq'],
    }

    exec { "Set MySQL server root password":
    	 subscribe => [ Package["mysql-server"]],
	 refreshonly => true,
	 unless => "mysqladmin -uroot -psecret status",
	 path => "/bin:/usr/bin",
	 command => "mysqladmin -uroot password secret",
    }

}
