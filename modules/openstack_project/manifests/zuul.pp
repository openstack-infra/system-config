# == Class: openstack_project::zuul
#
class openstack_project::zuul(
  $jenkins_server = '',
  $jenkins_user = '',
  $jenkins_apikey = '',
  $gerrit_server = '',
  $gerrit_user = '',
  $url_pattern = ''
) {

  class { '::zuul':
    jenkins_server   => $jenkins_server,
    jenkins_user     => $jenkins_user,
    jenkins_apikey   => $jenkins_apikey,
    gerrit_server    => $gerrit_server,
    gerrit_user      => $gerrit_user,
    url_pattern      => $url_pattern,
    push_change_refs => true
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
