# == Class: openstack_project::slave
#
class openstack_project::slave (
  $bare = false,
  $certname = $::fqdn,
  $ssh_key = '',
  $sysadmins = [],
  $python3 = false,
  $include_pypy = false,
  $gerrit_site = 'https://review.openstack.org',
  $git_protocol = 'git://',
  $git_site = 'git.openstack.org',
  $pypi_mirror = 'http://pypi.openstack.org/openstack',
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
    bare         => $bare,
    ssh_key      => $ssh_key,
    python3      => $python3,
    include_pypy => $include_pypy,
  }
  class { 'infra_vars':
    gerrit_site  => $gerrit_site,
    git_protocol => $git_protocol,
    git_site     => $git_site,
    pypi_mirror  => $pypi_mirror,
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
}
