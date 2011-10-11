class orchestra {
    $mysql_pass = generate('/usr/bin/openssl', 'rand', '-hex', '12')
    package { ipmitool: ensure => present }
    package { ubuntu-orchestra-server: ensure => present }
    exec { cobbler-sync:
      command => "/usr/bin/cobbler sync",
      logoutput => true,
      refreshonly => true,
      subscribe => [
        File["/etc/cobbler/dnsmasq.template"],
        File["/var/lib/cobbler/snippets/openstack_module_blacklist"],
        File["/var/lib/cobbler/snippets/openstack_cloud_init"],
        File["/var/lib/cobbler/snippets/openstack_network_sleep"],
        File["/var/lib/cobbler/snippets/openstack_mysql_password"],
        File["/var/lib/cobbler/kickstarts/openstack-test.preseed"],
	],
    }
    exec { rsyslog-restart:
      command => "/sbin/restart rsyslog",
      logoutput => true,
      refreshonly => true,
      subscribe => [
        File["/etc/rsyslog.d/99-orchestra.conf"],
	],
    }
    file { '/var/lib/cobbler/snippets/openstack_mysql_password':
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      content	  => template('orchestra/openstack_mysql_password.erb'),
      replace	  => 'false',
    }
    file { "/etc/cobbler/dnsmasq.template":
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source =>  "puppet:///modules/orchestra/dnsmasq.template",
      replace => 'true',
      require => Package["ubuntu-orchestra-server"],
    }
    file { "/var/lib/cobbler/snippets/openstack_module_blacklist":
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source =>  "puppet:///modules/orchestra/openstack_module_blacklist",
      replace => 'true',
      require => Package["ubuntu-orchestra-server"],
    }
    file { "/var/lib/cobbler/snippets/openstack_cloud_init":
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source =>  "puppet:///modules/orchestra/openstack_cloud_init",
      replace => 'true',
      require => Package["ubuntu-orchestra-server"],
    }
    file { "/var/lib/cobbler/snippets/openstack_network_sleep":
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source =>  "puppet:///modules/orchestra/openstack_network_sleep",
      replace => 'true',
      require => Package["ubuntu-orchestra-server"],
    }
    file { "/var/lib/cobbler/kickstarts/openstack-test.preseed":
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source =>  "puppet:///modules/orchestra/openstack-test.preseed",
      replace => 'true',
      require => Package["ubuntu-orchestra-server"],
    }
    file { "/etc/sudoers.d/orchestra-jenkins":
      owner => 'root',
      group => 'root',
      mode => 440,
      ensure => 'present',
      source =>  "puppet:///modules/orchestra/orchestra-jenkins-sudoers",
      replace => 'true',
    }
    file { "/etc/rsyslog.d/99-orchestra.conf":
      owner => 'root',
      group => 'root',
      mode => 440,
      ensure => 'present',
      source =>  "puppet:///modules/orchestra/99-orchestra.conf",
      replace => 'true',
    }
}
