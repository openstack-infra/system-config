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

  # A lightweight Fedora 20 x86_64 binary only mirror for
  # testing/updates/release only
  # Mirror URL paths are provided to follow the normal Fedora mirroring
  # conventions to allow for easy baseurl configuration
  yum::repo { 'f20-x86_64-updates-testing':
    description => 'Fedora 20 - x86_64 - Updates Testing',
    mirrorlist  => 'https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f20&arch=x86_64',
    cron_hour   => 0,
    cron_minute => 15,
    url_path    => 'fedora/updates/testing/20/x86_64/',
  }

  yum::repo { 'f20-x86_64-updates':
    description  => 'Fedora 20 - x86_64 - Updates',
    mirrorlist   => 'https://mirrors.fedoraproject.org/metalink?repo=updates-released-f20&arch=x86_64',
    cron_hour    => 1,
    cron_minute  => 15,
    url_path     => 'fedora/updates/20/x86_64/',
  }

  yum::repo { 'f20-x86_64-release':
    description  => 'Fedora 20 - x86_64 - Release',
    mirrorlist   => 'https://mirrors.fedoraproject.org/metalink?repo=fedora-20&arch=x86_64',
    cron_hour    => 2,
    cron_minute  => 15,
    url_path     => 'fedora/releases/20/Everything/x86_64',
  }

}
