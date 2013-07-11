# == Class: cgit
#
class cgit($vhost_name=git.openstack.org) {

  include apache

  package { [
      'cgit',
      'git-daemon',
    ]:
    ensure => present,
  }

  service { 'httpd':
    ensure     => running,
    require    => Package['httpd'],
  }

  file { '/var/lib/cgit':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  exec { 'restorecon -R -v /var/lib/git":
    path      => "/sbin",
    subscribe => Folder["/var/lib/cgit"]
   }

  selboolean { httpd_enable_cgi:
    persistent => true,
    value => on
  }

  file { "/etc/httpd/conf.d/cgit.conf":
    ensure  => present,
    source  => 'puppet:///modules/cgit/cgit.conf',
    mode    => '0644',
  }

}
