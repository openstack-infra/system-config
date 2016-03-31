# == Class: openstack_project::template
#
# A template host with no running services
#
class openstack_project::bootstrap (
  $purge_apt_sources = false,
) {
  case $::osfamily {
    'Debian': {
      # Purge and augment existing /etc/apt/sources.list if requested
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
      }
    }
  }

  # Which Puppet do I take?
  # Take $puppet_version and pin to that version
  if ($::osfamily == 'Debian') {
    # NOTE(pabelanger): Puppetlabs only support Ubuntu Trusty and below,
    # anything greater will use the OS version of puppet.
    if ($::operatingsystemrelease < '15.04') {
      apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        repos    => 'main',
        key      => {
          'id'     =>'47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
          'server' => 'pgp.mit.edu',
        },
      }
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

    file { '/etc/apt/preferences.d/00-puppet.pref':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('openstack_project/00-puppet.pref.erb'),
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
    if ($::operatingsystemmajrelease == '6') {
      $puppet_repo_source_path =
        'puppet:///modules/openstack_project/centos6-puppetlabs.repo'
      $custom_cgit = present
    } elsif ($::operatingsystemmajrelease == '7') {
      $puppet_repo_source_path =
        'puppet:///modules/openstack_project/centos7-puppetlabs.repo'
      $custom_cgit = absent
    }
    file { '/etc/yum.repos.d/puppetlabs.repo':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => $puppet_repo_source_path,
      replace => true,
    }

    # This git package includes a small work-around for slow https
    # cloning performance, as discussed in redhat bz#1237395.  Should
    # be fixed in 6.8
    file { '/etc/yum.repos.d/git-1237395.repo':
      ensure  => $custom_cgit,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/git-1237395.repo',
      replace => true,
    }
  }
}
