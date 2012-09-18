class openstack_project::static (
  $sysadmins = []
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80, 443],
    sysadmins => $sysadmins
  }

  include openstack_project
  class { 'jenkins::jenkinsuser':
    ssh_key => $openstack_project::jenkins_ssh_key
  }

  include apache

  apache::vhost { 'tarballs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/tarballs',
    require  => File['/srv/static/tarballs'],
  }

  apache::vhost { 'ci.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/ci',
    require  => File['/srv/static/ci'],
  }

  apache::vhost { 'logs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/logs',
    require  => File['/srv/static/logs'],
    template => 'openstack_project/logs.vhost.erb',
  }

  file { '/srv/static':
    ensure => directory
  }

  file { '/srv/static/tarballs':
    ensure => directory
  }

  file { '/srv/static/ci':
    ensure => directory
  }

  file { '/srv/static/logs':
    ensure => directory
  }

  cron { "gziplogs":
    user => root,
    hour => "*/6",
    command => 'sleep $((RANDOM\%600)) && flock -n /var/run/gziplogs.lock find /srv/static/logs/ \( -name \*.txt -or -name \*.html \) -exec gzip \{\} \;',
    environment => "PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  }

}
