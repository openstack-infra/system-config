# == Class: openstack_project::yum_mirror
#
class openstack_project::yum_mirror (
  $sysadmins = [],
) {

  include openstack_project
  include yum::mirror

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins                 => $sysadmins,
  }

  # Fedora 20 x86_64 binary only mirror for testing/updates/release
  yum::repo { 'f20-x86_64-updates-testing':
    description => 'Fedora 20 - x86_64 - Updates Testing',
    mirrorlist  => 'https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f20&arch=x86_64',
    cron_hour   => 0,
    cron_minute => 15,
  }

  yum::repo { 'f20-x86_64-updates':
    description  => 'Fedora 20 - x86_64 - Updates',
    mirrorlist   => 'https://mirrors.fedoraproject.org/metalink?repo=updates-released-f20&arch=x86_64',
    cron_hour    => 1,
    cron_minute  => 15,
  }

  yum::repo { 'f20-x86_64-release':
    description  => 'Fedora 20 - x86_64 - Release',
    mirrorlist   => 'https://mirrors.fedoraproject.org/metalink?repo=fedora-20&arch=x86_64',
    cron_hour    => 2,
    cron_minute  => 15,
  }

}
