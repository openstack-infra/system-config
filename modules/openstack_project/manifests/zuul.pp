# == Class: openstack_project::zuul
#
class openstack_project::zuul(
  $vhost_name = $::fqdn,
  $jenkins_host = '',
  $jenkins_url = '',
  $jenkins_user = '',
  $jenkins_apikey = '',
  $gerrit_server = '',
  $gerrit_user = '',
  $zuul_ssh_private_key = '',
  $url_pattern = '',
  $sysadmins = [],
  $statsd_host = '',
  $gearman_workers = []
) {

  # Turn a list of hostnames into a list of iptables rules
  $iptables_rules6 = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')
  $iptables_rules4 = $iptables_rules6

  $iptables_rules4 += [ "-m state --state NEW -m tcp -p tcp --dport 8001 -s ${jenkins_host} -j ACCEPT" ]

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    iptables_rules6           => $iptables_rules6,
    iptables_rules4           => $iptables_rules4,
    sysadmins                 => $sysadmins,
  }

  class { '::zuul':
    vhost_name           => $vhost_name,
    jenkins_server       => $jenkins_url,
    jenkins_user         => $jenkins_user,
    jenkins_apikey       => $jenkins_apikey,
    gerrit_server        => $gerrit_server,
    gerrit_user          => $gerrit_user,
    zuul_ssh_private_key => $zuul_ssh_private_key,
    url_pattern          => $url_pattern,
    push_change_refs     => false,
    status_url           => 'http://status.openstack.org/zuul/',
    statsd_host          => $statsd_host,
  }

  file { '/etc/zuul/layout.yaml':
    ensure => present,
    source => 'puppet:///modules/openstack_project/zuul/layout.yaml',
    notify => Exec['zuul-reload'],
  }
  file { '/etc/zuul/openstack_functions.py':
    ensure => present,
    source => 'puppet:///modules/openstack_project/zuul/openstack_functions.py',
    notify => Exec['zuul-reload'],
  }
  file { '/etc/zuul/logging.conf':
    ensure => present,
    source => 'puppet:///modules/openstack_project/zuul/logging.conf',
    notify => Exec['zuul-reload'],
  }

  class { '::recheckwatch':
    gerrit_server                => $gerrit_server,
    gerrit_user                  => $gerrit_user,
    recheckwatch_ssh_private_key => $zuul_ssh_private_key,
  }

  file { '/var/lib/recheckwatch/scoreboard.html':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/scoreboard.html',
    require => File['/var/lib/recheckwatch'],
  }

  file { '/var/lib/zuul/www':
    ensure  => absent,
  }

  file { '/var/lib/zuul/www/index.html':
    ensure  => absent,
  }

  package { 'libjs-jquery':
    ensure => absent,
  }

  file { '/var/lib/zuul/www/jquery.min.js':
    ensure  => absent,
  }

  file { '/var/lib/zuul/www/status.js':
    ensure  => absent,
  }

  file { '/opt/jquery-visibility':
    ensure   => absent,
  }

  file { '/var/lib/zuul/www/jquery-visibility.min.js':
    ensure   => absent,
  }

  file { '/opt/jquery-graphite':
    ensure   => absent,
  }

  file { '/var/lib/zuul/www/jquery-graphite.js':
    ensure   => absent,
  }
}
