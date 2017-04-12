# == Class: openstack_project::slave_common
#
# Common configuration between openstack_project::slave and
# openstack_project::single_use_slave
class openstack_project::slave_common(
  $sudo         = false,
){
  vcsrepo { '/opt/requirements':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack/requirements',
  }

  file { '/home/jenkins/.pydistutils.cfg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/pydistutils.cfg',
    require => Class['jenkins::jenkinsuser'],
  }

  if ($sudo == true) {
    file { '/etc/sudoers.d/jenkins-sudo':
      ensure => present,
      source => 'puppet:///modules/openstack_project/jenkins-sudo.sudo',
      owner  => 'root',
      group  => 'root',
      mode   => '0440',
    }
  }

  file { '/etc/sudoers.d/jenkins-sudo-grep':
    ensure => present,
    source => 'puppet:///modules/openstack_project/jenkins-sudo-grep.sudo',
    owner  => 'root',
    group  => 'root',
    mode   => '0440',
  }

  # install linux-headers depending on OS version
  case $::osfamily {
    'RedHat': {

      if ! defined(Package['kernel-devel']) {
        package { 'kernel-devel':
          ensure => present,
        }
      }

      if ! defined(Package['kernel-headers']) {
        package { 'kernel-headers':
          ensure => present,
        }
      }
    }
    'Debian': {
      if ($::operatingsystem == 'Debian') {
        # install depending on architecture
        case $::architecture {
          'amd64', 'x86_64': {
            $headers_package = ['linux-headers-amd64']
          }
          'x86': {
            $headers_package = ['linux-headers-686-pae']
          }
          default: {
            $headers_package = ["linux-headers-${::kernelrelease}"]
          }
        }
        if ! defined(Package[$headers_package]) {
          package { $headers_package:
            ensure => present,
          }
        }
      }
      else {
        if ($::lsbdistcodename == 'precise') {
          if ! defined(Package['linux-headers-virtual']) {
            package { 'linux-headers-virtual':
              ensure => present,
            }
          }
          if ! defined(Package['linux-headers-generic']) {
            package { 'linux-headers-generic':
              ensure => present,
            }
          }
        }
        else {
          # In trusty (and later), linux-headers-virtual is a transitional package that
          # simply depends on linux-headers-generic, so there is no need to specify it
          # any more.  Specifying it when installing on an arm64 host causes an error,
          # as linux-headers-virtual does not exist for arm64/aarch64.
          if ! defined(Package['linux-headers-generic']) {
            package { 'linux-headers-generic':
              ensure => present,
            }
          }
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}.")
    }
  }
}
