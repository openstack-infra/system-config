# == Class: openstack_project::server
#
# A server that we expect to run for some time
class openstack_project::server (
  $iptables_public_tcp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $sysadmins                 = [],
  $certname                  = $::fqdn
) {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports,
    iptables_rules4           => $iptables_rules4,
    iptables_rules6           => $iptables_rules6,
    certname                  => $certname,
  }
  class { 'exim':
    sysadmin => $sysadmins,
  }

  # Custom rsyslog config to disable /dev/xconsole noise on Debuntu servers
  if $::osfamily == 'Debian' {
    file { '/etc/rsyslog.d/50-default.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  =>
        'puppet:///modules/openstack_project/rsyslog.d_50-default.conf',
      replace => true,
    }
    service { 'rsyslog':
      ensure      => running,
      hasrestart  => true,
      subscribe   => File['/etc/rsyslog.d/50-default.conf'],
    }
  }
}
