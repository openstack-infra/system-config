# == Class: openstack_project::server
#
# A server that we expect to run for some time
class openstack_project::server (
  $iptables_public_tcp_ports = [],
  $iptables_public_udp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $sysadmins                 = [],
  $certname                  = $::fqdn,
  $pin_puppet                = '3.',
  $ca_server                 = undef,
  $enable_unbound            = true,
  $afs                       = false,
  $afs_cache_size            = 500000,
  $manage_exim               = true,
  $pypi_index_url            = 'https://pypi.python.org/simple',
  $purge_apt_sources         = true,
) {
  include openstack_project::params

  if $::osfamily == 'Debian' {
     # Purge and augment existing /etc/apt/sources.list if requested, and make
     # sure apt-get update is run before any packages are installed
     class { '::apt':
       purge => { 'sources.list' => $purge_apt_sources }
     }
     if $purge_apt_sources == true {
       file { '/etc/apt/sources.list.d/openstack-infra.list':
         ensure => present,
         group  => 'root',
         mode   => '0444',
         owner  => 'root',
         source => "puppet:///modules/openstack_project/sources.list.${::lsbdistcodename}",
       }
       exec { 'update-apt':
           command     => 'apt-get update',
           refreshonly => true,
           path        => '/bin:/usr/bin',
           subscribe   => File['/etc/apt/sources.list.d/openstack-infra.list'],
       }
       Exec['update-apt'] -> Package <| |>
     }
   }

  package { $::openstack_project::params::packages:
    ensure => present
  }

  ###########################################################
  # Manage  ntp

  include '::ntp'

  if ($::osfamily == "RedHat") {
    # Utils in ntp-perl are included in Debian's ntp package; we
    # add it here for consistency.  See also
    # https://tickets.puppetlabs.com/browse/MODULES-3660
    package { 'ntp-perl':
      ensure => present
    }
    # NOTE(pabelanger): We need to ensure ntpdate service starts on boot for
    # centos-7.  Currently, ntpd explicitly require ntpdate to be running before
    # the sync process can happen in ntpd.  As a result, if ntpdate is not
    # running, ntpd will start but fail to sync because of DNS is not properly
    # setup.
    package { 'ntpdate':
      ensure => present,
    }
    service { 'ntpdate':
      enable => true,
      require => Package['ntpdate'],
    }
  }

  ###########################################################
  # Process if ( $high_level_directive ) blocks

  if ($enable_unbound) {
    class { 'unbound':
      install_resolv_conf => $install_resolv_conf
    }
  }

  if $manage_exim {
    class { 'exim':
      sysadmins => $sysadmins,
    }
  }

  class { 'openstack_project::automatic_upgrades':
    origins => ["Puppetlabs:${lsbdistcodename}"],
  }

  include snmpd

  # We don't like byobu
  file { '/etc/profile.d/Z98-byobu.sh':
    ensure => absent,
  }

  if $::osfamily == 'Debian' {
    # Ubuntu installs their whoopsie package by default, but it eats through
    # memory and we don't need it on servers
    package { 'whoopsie':
      ensure => absent,
    }

    package { 'popularity-contest':
      ensure => absent,
    }
  }

  class { 'openstack_project::template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports,
    iptables_public_udp_ports => $iptables_public_udp_ports,
    iptables_rules4           => $iptables_rules4,
    iptables_rules6           => $iptables_rules6,
    snmp_v4hosts              => [
      '104.239.135.208',
      '104.130.253.206',
    ],
    snmp_v6hosts              => [
      '2001:4800:7819:104:be76:4eff:fe05:1d6a',
      '2001:4800:7818:103:be76:4eff:fe04:7ed0',
    ],
    certname                  => $certname,
    pin_puppet                => $pin_puppet,
    ca_server                 => $ca_server,
    afs                       => $afs,
    afs_cache_size            => $afs_cache_size,
    sysadmins                 => $sysadmins,
    pypi_index_url            => $pypi_index_url,
  }

}
