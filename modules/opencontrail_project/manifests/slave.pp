# == Class: opencontrail_project::slave
#
class opencontrail_project::slave (
  $bare = false,
  $certname = $::fqdn,
  $ssh_key = '',
  $sysadmins = [],
  $python3 = false,
  $include_pypy = false
) {
  include opencontrail_project
  include opencontrail_project::tmpcleanup
  class { 'opencontrail_project::automatic_upgrades':
    origins => ['LP-PPA-saltstack-salt precise'],
  }
  class { 'opencontrail_project::server':
    iptables_public_tcp_ports => [],
    certname                  => $certname,
    sysadmins                 => $sysadmins,
  }
  class { 'jenkins::slave':
    bare         => $bare,
    ssh_key      => $ssh_key,
    python3      => $python3,
    include_pypy => $include_pypy,
  }
  class { 'salt':
    salt_master => 'ci-puppetmaster.opencontrail.org',
  }
  include jenkins::cgroups
  include ulimit
  ulimit::conf { 'limit_jenkins_procs':
    limit_domain => 'jenkins',
    limit_type   => 'hard',
    limit_item   => 'nproc',
    limit_value  => '256'
  }
}
