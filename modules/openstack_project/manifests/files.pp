# == Class: openstack_project::files
#
class openstack_project::files (
  $vhost_name = $::fqdn,
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

  ###########################################################
  # docs.openstack.org

  ::httpd::vhost { 'docs.openstack.org':
    port       => 80,
    docroot    => "${afs_root}docs",
    priority   => '50',
    template   => 'openstack_project/docs.vhost.erb',
    serveraliases => 'docs-beta.openstack.org',
    require       => [
      Vcsrepo['/opt/openstack-manuals'],
    ],
  }

  # For www/setup/RewriteRules.inc
  vcsrepo { '/opt/openstack-manuals':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack/openstack-manuals.git',
  }

}
