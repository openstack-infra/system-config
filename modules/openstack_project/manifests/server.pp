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
  $puppetmaster_server       = 'puppetmaster.openstack.org',
  $manage_exim               = true,
  $pypi_index_url            = 'https://pypi.python.org/simple',
  $purge_apt_sources         = true,
) {
  class { 'openstack_project::template':
    iptables_public_tcp_ports => $iptables_public_tcp_ports,
    iptables_public_udp_ports => $iptables_public_udp_ports,
    iptables_rules4           => $iptables_rules4,
    iptables_rules6           => $iptables_rules6,
    certname                  => $certname,
    pin_puppet                => $pin_puppet,
    ca_server                 => $ca_server,
    puppetmaster_server       => $puppetmaster_server,
    enable_unbound            => $enable_unbound,
    afs                       => $afs,
    afs_cache_size            => $afs_cache_size,
    manage_exim               => $manage_exim,
    sysadmins                 => $sysadmins,
    pypi_index_url            => $pypi_index_url,
  }
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
}
