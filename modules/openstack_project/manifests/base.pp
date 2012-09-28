class openstack_project::base(
  $certname = $::fqdn,
  $install_users = true
) {
  include openstack_project::users
  include sudoers

  file { '/etc/profile.d/Z98-byobu.sh':
    ensure => 'absent'
  }

  package { 'popularity-contest':
    ensure => purged
  }

  if ($::lsbdistcodename == 'oneiric') {
    include apt
    apt::ppa { 'ppa:git-core/ppa': }
    package { 'git':
      ensure  => latest,
      require => Apt::Ppa['ppa:git-core/ppa']
    }
  } else {
    package { 'git':
      ensure => present,
    }
  }

  $packages = [
    'puppet',
    'python-setuptools',
  ]

  package { $packages:
    ensure => 'present'
  }

  include pip
  package { 'virtualenv':
    ensure => latest,
    provider => pip,
    require => Class[pip]
  }

  if ($install_users) {
    package { ['byobu', 'emacs23-nox']:
      ensure => 'present'
    }

    realize (
      User::Virtual::Localuser['mordred'],
      User::Virtual::Localuser['corvus'],
      User::Virtual::Localuser['soren'],
      User::Virtual::Localuser['linuxjedi'],
      User::Virtual::Localuser['devananda'],
      User::Virtual::Localuser['clarkb'],
    )
  }

  # Download and set up puppet apt repo
  exec { "download:puppetlabs-release-$::{lsbdistcodename}.deb":
    command => "/usr/bin/wget http://apt.puppetlabs.com/puppetlabs-release-$::{lsbdistcodename}.deb -O /root/puppetlabs-release-$::{lsbdistcodename}.deb",
    creates => "/root/puppetlabs-release-$::{lsbdistcodename}.deb",
  }
  exec { "dpkg:puppetlabs-release-$::{lsbdistcodename}.deb":
    command => "/usr/bin/dpkg -i /root/puppetlabs-release-$::{lsbdistcodename}.deb",
    onlyif  => '/usr/bin/test ! -f /etc/apt/sources.list.d/puppetlabs.list',
    require => Exec["download:puppetlabs-release-$::{lsbdistcodename}.deb"],
  }

  file { '/etc/puppet/puppet.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('openstack_project/puppet.conf.erb'),
    replace => true,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
