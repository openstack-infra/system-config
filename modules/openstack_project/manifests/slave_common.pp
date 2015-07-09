# == Class: openstack_project::slave_common
#
# Common configuration between openstack_project::slave and
# openstack_project::single_use_slave
class openstack_project::slave_common(
  $sudo         = false,
  $project_config_repo = '',
){
  vcsrepo { '/opt/requirements':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack/requirements',
  }

  class { 'project_config':
    url  => $project_config_repo,
  }

  file { '/usr/local/jenkins/slave_scripts':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    require => [File['/usr/local/jenkins'],
                $::project_config::config_dir],
    source  => $::project_config::jenkins_scripts_dir,
  }

  file { '/home/jenkins/.pydistutils.cfg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/pydistutils.cfg',
    require => Class['jenkins::slave'],
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

  # Temporary for debugging glance launch problem
  # https://lists.launchpad.net/openstack/msg13381.html
  # NOTE(dprince): ubuntu only as RHEL6 doesn't have sysctl.d yet
  if ($::osfamily == 'Debian') {

    file { '/etc/sysctl.d/10-ptrace.conf':
      ensure => present,
      source => 'puppet:///modules/jenkins/10-ptrace.conf',
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
    }

    exec { 'ptrace sysctl':
      subscribe   => File['/etc/sysctl.d/10-ptrace.conf'],
      refreshonly => true,
      command     => '/sbin/sysctl -p /etc/sysctl.d/10-ptrace.conf',
    }
  }

  # install linux-headers depending on OS version
  case $::osfamily {
    'RedHat': {
      $header_packages = ['kernel-devel', 'kernel-headers']
    }
    'Debian': {
      if ($::operatingsystem == 'Debian') {
          # install depending on kernel release
          $header_packages = [ "linux-headers-${::kernelrelease}", ]
      }
      else {
        if ($::lsbdistcodename == 'precise') {
          $header_packages = ['linux-headers-virtual', 'linux-headers-generic']
        }
        else {
          # In trusty (and later), linux-headers-virtual is a transitional package that
          # simply depends on linux-headers-generic, so there is no need to specify it
          # any more.  Specifying it when installing on an arm64 host causes an error,
          # as linux-headers-virtual does not exist for arm64/aarch64.
          $header_packages = ['linux-headers-generic']
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}.")
    }
  }

  package { $header_packages:
    ensure => present
  }

  python::virtualenv { '/usr/zuul-env':
    ensure       => present,
    owner        => 'root',
    group        => 'root',
    timeout      => 0,
  }

  python::pip { 'zuul' :
    pkgname      => 'zuul',
    virtualenv   => '/usr/zuul-env',
    owner        => 'root',
    install_args => ['-e'],
    url          => 'git+https://git.openstack.org/openstack-infra/zuul',
   }
}
