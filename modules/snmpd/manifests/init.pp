class snmpd {
    package { snmpd: ensure => present }
    service { snmpd:
      ensure          => running,
      hasrestart      => true,
      require => [File["/etc/snmp/snmpd.conf"],
                  File["/etc/init.d/snmpd"]]
    }
    # This file is only needed on machines pre-precise. There is a bug in
    # the previous init script versions which causes them to attempt
    # snmptrapd even if it's configured not to run, and then to report
    # failure.
    file { "/etc/init.d/snmpd":
      owner => 'root',
      group => 'root',
      mode => 755,
      ensure => 'present',
      source => 'puppet:///modules/snmpd/snmpd.init',
      replace => 'true',
      require => Package[snmpd]
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
