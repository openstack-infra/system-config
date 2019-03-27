# == Class: openstack_project::grafana
#
# === Parameters
# [*cfg*]
# Manages the Grafana configuration file. The upstream puppet-grafana module
# documentaion: https://github.com/bfraser/puppet-grafana#cfg
#
class openstack_project::grafana (
  $mysql_password,
  $admin_password = '',
  $admin_user = 'admin',
  $grafana_cfg = {},
  $http_host = '127.0.0.1',
  $http_port = '8080',
  $mysql_host = '127.0.0.1',
  $mysql_name = 'grafana',
  $mysql_user = 'grafana',
  $project_config_repo = '',
  $secret_key = '',
  $vhost_name = $::fqdn,
) {
  include ::httpd

  $grafana_cfg_defaults = {
    # NOTE(pabelanger): app_mode must be the first key!
    'app_mode' => 'production',
    'analytics' => {
      'reporting_enabled' => false,
    },
    'auth.anonymous' => {
      'enabled' => true,
    },
    'database' => {
      'type'     => 'mysql',
      'host'     => "${mysql_host}:3306",
      'name'     => $mysql_name,
      'user'     => $mysql_user,
      'password' => $mysql_password,
    },
    'security' => {
      'admin_password' => $admin_password,
      'admin_user'     => $admin_user,
      'secret_key'     => $secret_key,
    },
    'server'   => {
      'http_addr' => $http_host,
      'http_port' => $http_port,
    },
    'users'    => {
      'allow_sign_up' => false,
    },
  }

  $grafana_cfg_merged = merge($grafana_cfg_defaults, $grafana_cfg)

  $version = '5.1.3'

  class { '::grafana':
    cfg            => $grafana_cfg_merged,
    # Note that we can't use archive because that install_method requires
    # the camptocamp-archive module but we have puppetcommunity-archive
    # in modules.env, and puppet only supports having one in the modulepath
    # at a time.
    install_method => 'repo',
    version        => $version,
  }

  ::httpd::vhost { $vhost_name:
    docroot  => 'MEANINGLESS ARGUMENT',
    port     => 80,
    priority => '50',
    template => 'openstack_project/grafana.vhost.erb',
  }

  if ! defined(Httpd::Mod['rewrite']) {
    httpd::mod { 'rewrite':
        ensure => present,
    }
  }

  if ! defined(Httpd::Mod['proxy']) {
    httpd::mod { 'proxy':
        ensure => present,
    }
  }

  if ! defined(Httpd::Mod['proxy_http']) {
    httpd::mod { 'proxy_http':
        ensure => present,
    }
  }

  class { '::project_config':
    url  => $project_config_repo,
  }

  class { '::grafyaml':
    config_dir  => $::project_config::grafana_dashboards_dir,
    grafana_url => "http://${admin_user}:${admin_password}@${http_host}:${http_port}",
    require     => Class['grafana'],
  }
}
