# Class to configure cgit on a CentOS node.
#
# == Class: openstack_project::static
class openstack_project::git (
  $sysadmins = [],
  $git_gerrit_ssh_key = $git_gerrit_ssh_key,
  $gerrit_url = 'review.openstack.org'
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 9418],
    sysadmins                 => $sysadmins,
  }

  include cgit

  file { '/etc/cgitrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/git/cgitrc'
  }

  file { '/home/cgit/.ssh/':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0700',
    require => User['cgit'],
  }

  file { '/home/cgit/.ssh/known_hosts':
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0600',
    content => "${gerrit_url} ${git_gerrit_ssh_key}",
    replace => true,
    require => File['/home/cgit/.ssh/']
  }

  class { 'selinux':
    mode => 'enforcing'
  }
}
