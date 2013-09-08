# User group management dev server
class openstack_project::groups_dev (
  $site_admin_password = '',
  $site_mysql_host     = '',
  $site_mysql_password = '',
  $sysadmins = [],
) {

#  include drupal

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  class { 'drupal':
    site_name            => 'groups-dev.openstack.org',
    site_docroot         => '/srv/vhosts/groups-dev.openstack.org',
    site_mysql_host      => $site_mysql_host,
    site_mysql_user      => 'groups',
    site_mysql_password  => $site_mysql_password,
    site_mysql_database  => 'groups_dev',
    site_vhost_root      => '/srv/vhosts',
    site_staging_tarball => 'osgroups-dev.tar.gz',
    site_admin_password  => $site_admin_password,
    site_build_reponame  => 'groups-master',
    site_makefile        => 'build-osgroups.make',
    site_repo_url        => 'https://git.openstack.org/openstack-infra/groups',
    site_profile         => 'osgroups',
    site_base_url        => 'http://groups-dev.openstack.org',
    require              => Class['openstack_project::server'],
  }

}
