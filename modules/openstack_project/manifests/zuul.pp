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
  $statsd_host = ''
) {

  $rules = [ "-m state --state NEW -m tcp -p tcp --dport 8001 -s ${jenkins_host} -j ACCEPT" ]

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    iptables_rules4           => $rules,
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
    status_url           => "http://${::fqdn}/",
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
    ensure  => directory,
    require => File['/var/lib/zuul'],
  }

  file { '/var/lib/zuul/www/index.html':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/status.html',
    require => File['/var/lib/zuul/www'],
  }

  package { 'libjs-jquery':
    ensure => present,
  }

  file { '/var/lib/zuul/www/jquery.min.js':
    ensure  => link,
    target  => '/usr/share/javascript/jquery/jquery.min.js',
    require => [File['/var/lib/zuul/www'],
                Package['libjs-jquery']],
  }

  file { '/var/lib/zuul/www/status.js':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/zuul/status.js',
    require => File['/var/lib/zuul/www'],
  }

  vcsrepo { '/opt/jquery-visibility':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/mathiasbynens/jquery-visibility.git',
  }

  file { '/var/lib/zuul/www/jquery-visibility.min.js':
    ensure  => link,
    target  => '/opt/jquery-visibility/jquery-visibility.min.js',
    require => File['/var/lib/zuul/www'],
  }

  vcsrepo { '/opt/jquery-graphite':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/prestontimmons/graphitejs.git',
  }

  file { '/var/lib/zuul/www/jquery.graphite.js':
    ensure  => link,
    target  => '/opt/jquery-visibility/jquery-graphite.js',
    require => File['/var/lib/zuul/www'],
  }
}
