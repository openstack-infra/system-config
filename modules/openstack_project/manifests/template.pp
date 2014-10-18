# == Class: openstack_project::template
#
# A template host with no running services
#
class openstack_project::template (
  $iptables_public_tcp_ports = [],
  $iptables_public_udp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $pin_puppet                = '3.',
  $install_users             = true,
  $install_resolv_conf       = true,
  $automatic_upgrades        = true,
  $certname                  = $::fqdn,
  $ca_server                 = undef,
  $enable_unbound            = true,
  $afs                       = false,
) {
  include ntp
  include ssh
  include snmpd
  if $automatic_upgrades == true {
    class { 'openstack_project::automatic_upgrades':
      origins => ["Puppetlabs:${lsbdistcodename}"],
    }
  }

  if ( $afs ) {
    $all_udp = concat(
      $iptables_public_udp_ports, [7001])

    class { 'afs::client':
      cell         => 'openstack.org',
      realm        => 'OPENSTACK.ORG',
      admin_server => 'kdc.openstack.org',
      kdcs         => [
        'kdc01.openstack.org',
        'kdc02.openstack.org',
      ],
    }
  } else {
    $all_udp = $iptables_public_udp_ports
  }

  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
    public_udp_ports => $all_udp,
    rules4           => $iptables_rules4,
    rules6           => $iptables_rules6,
  }

  class { 'openstack_project::base':
    install_users => $install_users,
    certname      => $certname,
    pin_puppet    => $pin_puppet,
    ca_server     => $ca_server,
  }

  package { 'lvm2':
    ensure => present,
  }

  package { 'strace':
    ensure => present,
  }

  package { 'tcpdump':
    ensure => present,
  }

  if ($enable_unbound) {
    class { 'unbound':
      install_resolv_conf => $install_resolv_conf
    }
  }

  if $::osfamily == 'Debian' {
    # Make sure dig is installed
    package { 'dnsutils':
      ensure => present,
    }

    # Custom rsyslog config to disable /dev/xconsole noise on Debuntu servers
    file { '/etc/rsyslog.d/50-default.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  =>
        'puppet:///modules/openstack_project/rsyslog.d_50-default.conf',
      replace => true,
      notify  => $rsyslog_notify,
    }

    # Ubuntu installs their whoopsie package by default, but it eats through
    # memory and we don't need it on servers
    package { 'whoopsie':
      ensure => absent,
    }
  }

  if ($::in_chroot) {
    notify { 'rsyslog in chroot':
      message => 'rsyslog not refreshed, running in chroot',
    }
    $rsyslog_notify = []
  } else {
    service { 'rsyslog':
      ensure     => running,
      enable     => true,
      hasrestart => true,
    }
    $rsyslog_notify = [ Service['rsyslog'] ]
  }

  # Increase syslog message size in order to capture
  # python tracebacks with syslog.
  file { '/etc/rsyslog.d/99-maxsize.conf':
    ensure  => present,
    # Note MaxMessageSize is not a puppet variable.
    content => '$MaxMessageSize 6k',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => $rsyslog_notify,
  }

  if ($::osfamily == 'RedHat') {
    # Make sure dig is installed
    package { 'bind-utils':
      ensure => present,
    }
  }
}
