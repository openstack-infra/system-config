# User group management server staging
class openstack_project::groups_staging (
  $mysql_root_password = '',
  $site_admin_password = '',
  $site_mysql_password = '',
  $sysadmins = [],
) {

#  include drupal

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  realize (
    User::Virtual::Localuser['smaffulli'],
  )

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }

  class { 'drupal':
    site_name               => 'groups-staging.openstack.org',
    site_docroot            => '/srv/vhosts/groups-staging.openstack.org',
    site_mysql_host         => 'localhost',
    site_mysql_user         => 'groups',
    site_mysql_password     => $site_mysql_password,
    site_mysql_database     => 'groups_staging',
    site_vhost_root         => '/srv/vhosts',
    site_staging_tarball    => 'osgroups-staging.tar.gz',
    site_admin_password     => $site_admin_password,
    site_build_reponame     => 'groups-master',
    site_makefile           => 'build-osgroups.make',
    site_repo_url           => 'https://github.com/openstack-infra/groups.git',
    require                 => Package['mysql-server'],
  }

}
