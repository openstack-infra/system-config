# == Class: openstack_project::files
#
class openstack_project::files (
  $vhost_name = $::fqdn,
  $developer_cert_file_contents,
  $developer_key_file_contents,
  $developer_chain_file_contents,
  $docs_cert_file_contents,
  $docs_key_file_contents,
  $docs_chain_file_contents,
) {

  $afs_root = '/afs/openstack.org/'
  $www_base = '/var/www'

  #####################################################
  # Build Apache Webroot
  file { "${www_base}":
    ensure  => directory,
    owner   => root,
    group   => root,
  }

  file { "${www_base}/robots.txt":
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0444',
    source   => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require  => File["${www_base}"],
  }

  #####################################################
  # Set up directories needed by HTTPS certs/keys
  file { '/etc/ssl/certs':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/ssl/private':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  #####################################################
  # Build VHost
  include ::httpd

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => "${afs_root}",
    template => 'openstack_project/files.vhost.erb',
    require  => [
      File["${www_base}"],
    ]
  }

  httpd_mod { 'rewrite':
    ensure => present,
    before => Service['httpd'],
  }

  class { '::httpd::logrotate':
    options => [
      'daily',
      'missingok',
      'rotate 7',
      'compress',
      'delaycompress',
      'notifempty',
      'create 640 root adm',
    ],
  }

  # Until Apache 2.4.24 the event MPM has some issues scalability
  # bottlenecks that were seen to drop connections, especially on
  # larger files; see
  #  https://httpd.apache.org/docs/2.4/mod/event.html
  #
  # The main advantage of event MPM is for keep-alive requests which
  # are not really a big issue on this static file server.  Therefore
  # we switch to the threaded worker MPM as a workaround.  This can be
  # reconsidered when the apache version running is sufficient to
  # avoid these problems.

  httpd::mod { 'mpm_event': ensure => 'absent' }
  httpd::mod { 'mpm_worker': ensure => 'present' }

  ###########################################################
  # docs.openstack.org

  ::httpd::vhost { 'docs.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => "${afs_root}docs",
    priority   => '50',
    template   => 'openstack_project/docs.vhost.erb',
  }
  file { '/etc/ssl/certs/docs.openstack.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $docs_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/docs.openstack.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $docs_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/docs.openstack.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $docs_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/docs.openstack.org.pem'],
  }

  ###########################################################
  # developer.openstack.org

  ::httpd::vhost { 'developer.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => "${afs_root}developer-docs",
    priority   => '50',
    template   => 'openstack_project/developer.vhost.erb',
  }
  file { '/etc/ssl/certs/developer.openstack.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $developer_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/developer.openstack.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $developer_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/developer.openstack.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $developer_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/developer.openstack.org.pem'],
  }
}
