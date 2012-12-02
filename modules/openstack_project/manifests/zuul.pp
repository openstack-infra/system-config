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
  $sysadmins = []
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
    push_change_refs     => true
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
}
