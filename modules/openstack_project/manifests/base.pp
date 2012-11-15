# == Class: openstack_project::base
#
class openstack_project::base(
  $certname = $::fqdn,
  $install_users = true
) {
  include apt
  include openstack_project::users
  include sudoers

  file { '/etc/profile.d/Z98-byobu.sh':
    ensure => absent,
  }

  package { 'popularity-contest':
    ensure => purged,
  }

  if ($::lsbdistcodename == 'oneiric') {
    apt::ppa { 'ppa:git-core/ppa': }
    package { 'git':
      ensure  => latest,
      require => Apt::Ppa['ppa:git-core/ppa'],
    }
  } else {
    package { 'git':
      ensure => present,
    }
  }

  $packages = [
    'puppet',
    'python-setuptools',
    'wget',
  ]

  package { $packages:
    ensure => present,
  }

  include pip
  package { 'virtualenv':
    ensure   => latest,
    provider => pip,
    require  => Class['pip'],
  }

  if ($install_users) {
    package { ['byobu', 'emacs23-nox']:
      ensure => present,
    }

    realize (
      User::Virtual::Localuser['mordred'],
      User::Virtual::Localuser['corvus'],
      User::Virtual::Localuser['soren'],
      User::Virtual::Localuser['linuxjedi'],
      User::Virtual::Localuser['clarkb'],
      User::Virtual::Localuser['fungi'],
    )
  }

  # Use upstream puppet and pin to version 2.7.*
  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
  }

  file { '/etc/apt/preferences.d/00-puppet.pref':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/00-puppet.pref',
    replace => true,
  }

  file { '/etc/puppet/puppet.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('openstack_project/puppet.conf.erb'),
    replace => true,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
