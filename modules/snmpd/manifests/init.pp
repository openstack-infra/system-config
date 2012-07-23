class snmpd {
    package { snmpd: ensure => present }
    service { snmpd: 
      ensure          => running,
      hasrestart      => true,
      require => File["/etc/snmp/snmpd.conf"],
    }
    file { "/etc/init.d/snmpd":
      owner => 'root',
      group => 'root',
      mode => 755,
      ensure => 'present',
      source => 'puppet:///modules/snmpd/snmpd.init',
      replace => 'true',
    }
    file { "/etc/snmp/snmpd.conf":
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source => 'puppet:///modules/snmpd/snmpd.conf',
      replace => 'true',
    }
}
