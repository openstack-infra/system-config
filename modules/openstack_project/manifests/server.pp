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
  include sudoers
  include openstack_project::params

  class { 'timezone':
    timezone => 'Etc/UTC',
  }

  package { 'rsyslog':
    ensure => present,
  }

  service { 'rsyslog':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => Package['rsyslog'],
  }
  $rsyslog_notify = [ Service['rsyslog'] ]

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
    require => Package['rsyslog'],
  }

  if $::osfamily == 'Debian' {
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
      require => Package['rsyslog'],
    }

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
  # Manage Root ssh

  class { 'ssh':
    trusted_ssh_type   => 'address',
    trusted_ssh_source => '23.253.245.198,2001:4800:7818:101:3c21:a454:23ed:4072',
  }

  if ! defined(File['/root/.ssh']) {
    file { '/root/.ssh':
      ensure => directory,
      mode   => '0700',
    }
  }

  ssh_authorized_key { 'puppet-remote-2014-09-15':
    ensure  => present,
    user    => 'root',
    type    => 'ssh-rsa',
    key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDSLlN41ftgxkNeUi/kATYPwMPjJdMaSbgokSb9PSkRPZE7GeNai60BCfhu+ky8h5eMe70Bpwb7mQ7GAtHGXPNU1SRBPhMuVN9EYrQbt5KSiwuiTXtQHsWyYrSKtB+XGbl2PhpMQ/TPVtFoL5usxu/MYaakVkCEbt5IbPYNg88/NKPixicJuhi0qsd+l1X1zoc1+Fn87PlwMoIgfLIktwaL8hw9mzqr+pPcDIjCFQQWnjqJVEObOcMstBT20XwKj/ymiH+6p123nnlIHilACJzXhmIZIZO+EGkNF7KyXpcBSfv9efPI+VCE2TOv/scJFdEHtDFkl2kdUBYPC0wQ92rp',
    options => [
      'from="23.253.245.198,2001:4800:7818:101:3c21:a454:23ed:4072,localhost"',
    ],
    require => File['/root/.ssh'],
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

  ###########################################################
  # Manage  python/pip

  $desired_virtualenv = '13.1.0'
  class { '::pip':
    index_url       => $pypi_index_url,
    optional_settings => {
      'extra-index-url' => '',
    },
    manage_pip_conf => true,
  }

  if (( versioncmp($::virtualenv_version, $desired_virtualenv) < 0 )) {
    $virtualenv_ensure = $desired_virtualenv
  } else {
    $virtualenv_ensure = present
  }
  package { 'virtualenv':
    ensure   => $virtualenv_ensure,
    provider => openstack_pip,
    require  => Class['pip'],
  }

  ###########################################################
  # Turn off puppet service

  service { 'puppet':
    ensure => stopped,
    enable => false,
  }

  if $::osfamily == 'Debian' {
    file { '/etc/default/puppet':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/puppet.default',
      replace => true,
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
    puppetmaster_server       => $puppetmaster_server,
    afs                       => $afs,
    afs_cache_size            => $afs_cache_size,
    sysadmins                 => $sysadmins,
  }

}
