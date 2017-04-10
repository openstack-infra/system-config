# == Class: openstack_project::template
#
# A template host with no running services
#
class openstack_project::template (
  $iptables_public_tcp_ports = [],
  $iptables_public_udp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $snmp_v4hosts              = [],
  $snmp_v6hosts              = [],
  $pin_puppet                = '3.',
  $install_users             = true,
  $install_resolv_conf       = true,
  $automatic_upgrades        = true,
  $certname                  = $::fqdn,
  $ca_server                 = undef,
  $afs                       = false,
  $afs_cache_size            = 500000,
  $puppetmaster_server       = 'puppetmaster.openstack.org',
  $manage_exim               = false,
  $sysadmins                 = [],
  $pypi_index_url            = 'https://pypi.python.org/simple',
  $permit_root_login         = 'no',
) {

  ###########################################################
  # Classes for all hosts
  include sudoers

  include openstack_project::params
  include openstack_project::users

  class { 'ssh':
    trusted_ssh_type   => 'address',
    trusted_ssh_source => '23.253.245.198,2001:4800:7818:101:3c21:a454:23ed:4072',
    permit_root_login  => $permit_root_login,
  }

  if ( $afs ) {
    $all_udp = concat(
      $iptables_public_udp_ports, [7001])

    class { 'openafs::client':
      cell         => 'openstack.org',
      realm        => 'OPENSTACK.ORG',
      admin_server => 'kdc.openstack.org',
      cache_size   => $afs_cache_size,
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
    snmp_v4hosts     => $snmp_v4hosts,
    snmp_v6hosts     => $snmp_v6hosts,
  }

  class { 'timezone':
    timezone => 'Etc/UTC',
  }


  ###########################################################
  # Process if ( $high_level_directive ) blocks

  if $manage_exim {
    class { 'exim':
      sysadmins => $sysadmins,
    }
  }

  if $automatic_upgrades == true {
    class { 'openstack_project::automatic_upgrades':
      origins => ["Puppetlabs:${lsbdistcodename}"],
    }
  }

  class {'openstack_project::users_install':
    install_users => $install_users
  }

  package { 'rsyslog':
    ensure => present,
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
      require    => Package['rsyslog'],
    }
    $rsyslog_notify = [ Service['rsyslog'] ]
  }

  ###########################################################
  # System tweaks

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

  # We don't like byobu
  file { '/etc/profile.d/Z98-byobu.sh':
    ensure => absent,
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
  # Manage Root ssh

  if ! defined(File['/root/.ssh']) {
    file { '/root/.ssh':
      ensure => directory,
      mode   => '0700',
    }
  }

  ssh_authorized_key { 'puppet-remote-2014-04-17':
    ensure  => absent,
    user    => 'root',
  }
  ssh_authorized_key { 'puppet-remote-2014-05-24':
    ensure  => absent,
    user    => 'root',
  }
  ssh_authorized_key { 'puppet-remote-2014-09-11':
    ensure  => absent,
    user    => 'root',
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
  ssh_authorized_key { '/root/.ssh/authorized_keys':
    ensure  => absent,
    user    => 'root',
  }

  file_line { 'ensure NoRoaming for ssh clients':
    after => '^Host \*',
    path  => '/etc/ssh/ssh_config',
    line  => '    UseRoaming no',
  }

  if ($::osfamily == 'Debian') {
    # NOTE(pabelanger): Puppetlabs only support Ubuntu Trusty and below,
    # anything greater will use the OS version of puppet.
    if ($::operatingsystemrelease < '15.04') {
      include ::apt
      apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        repos    => 'main',
        key      => {
          'id'     =>'47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
          'server' => 'pgp.mit.edu',
        },
      }
    }

    file { '/etc/security/limits.d/60-nofile-limit.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/openstack_project/debian_limits.conf',
      replace => true,
    }

    file { '/etc/apt/apt.conf.d/80retry':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/80retry',
      replace => true,
    }

    file { '/etc/apt/apt.conf.d/90no-translations':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/90no-translations',
      replace => true,
    }

    file { '/etc/default/puppet':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/puppet.default',
      replace => true,
    }

  }

  if ($::operatingsystem == 'CentOS') {
    file { '/etc/yum.repos.d/puppetlabs.repo':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/centos7-puppetlabs.repo',
      replace => true,
    }
  }
  service { 'puppet':
    ensure => stopped,
    enable => false,
  }

  ###########################################################

}
