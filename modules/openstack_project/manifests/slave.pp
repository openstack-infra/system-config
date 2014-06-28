# == Class: openstack_project::slave
#
class openstack_project::slave (
  $thin = false,
  $certname = $::fqdn,
  $ssh_key = '',
  $sysadmins = [],
  $python3 = false,
  $include_pypy = false
) {

  include openstack_project
  include openstack_project::tmpcleanup

  class { 'openstack_project::automatic_upgrades':
    origins => ['LP-PPA-saltstack-salt precise'],
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [],
    certname                  => $certname,
    sysadmins                 => $sysadmins,
  }

  class { 'jenkins::slave':
    ssh_key      => $ssh_key,
    python3      => $python3,
  }

  file { '/home/jenkins/.pydistutils.cfg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/pydistutils.cfg',
    require => Class['jenkins::slave'],
  }

  file { '/home/jenkins/.pip':
    ensure  => directory,
    require => Class['jenkins::slave'],
  }

  file { '/home/jenkins/.pip/pip.conf':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/pip.conf',
    require => File['/home/jenkins/.pip'],
  }

  class { 'salt':
    salt_master => 'ci-puppetmaster.openstack.org',
  }

  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }

  class { 'openstack_project::slave_common':
    include_pypy => $include_pypy,
  }

  if (! $thin) {
    include openstack_project::thick_slave
  }

}
