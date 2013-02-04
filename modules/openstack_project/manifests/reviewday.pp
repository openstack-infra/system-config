# == Class: openstack_project::reviewday
#
class openstack_project::reviewday (
  $sysadmins = []
  $vhost_name = "reviewday.openstack.org"
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins,
  }
  include ::reviewday

  reviewday::site { 'openstack':
    git_url => 'https://github.com/openstack-infra/reviewday.git',
  }

  apache::vhost { $vhost_name:
    docroot  => "/srv/static/reviewday",
    port     => 80,
    priority => '50',
    require  => File['/srv/static/reviewday'],
  }

  cron { "update_reviewday_${site}":
    command => "cd /home/reviewday/openstack/ && PYTHONPATH=$PWD python bin/reviewday -o /srv/static/reviewday",
    minute  => '*/15',
    user    => 'reviewday',
  }
}
