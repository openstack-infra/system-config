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
  $mysql_host = '127.0.0.1',
  $mysql_name = 'grafana',
  $mysql_user = 'grafana',
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
      enabled => true,
    },
    'database' => {
      type     => 'mysql',
      host     => "${mysql_host}:3306",
      name     => $mysql_name,
      user     => $mysql_user,
      password => $mysql_password,
    },
    'security' => {
      admin_password => $admin_password,
      admin_user     => $admin_user,
      secret_key     => $secret_key,
    },
    'server'   => {
      http_addr => '127.0.0.1',
      http_port => 8080,
    },
    'users'    => {
      allow_sign_up => false,
    },
  }

  $grafana_cfg_merged = merge($grafana_cfg_defaults, $grafana_cfg)

  class { '::grafana':
    cfg            => $grafana_cfg_merged,
    # Note that we can't use archive because this class requires
    # the camptocamp-archive module than we have puppetcommunity-archive
    # in modules.env
    install_method => 'repo',
    version        => '2.1.0',
  }

  ::httpd::vhost { $vhost_name:
    docroot  => 'MEANINGLESS ARGUMENT',
    port     => 80,
    priority => '50',
    template => 'openstack_project/grafana.vhost.erb',
  }

  httpd_mod { 'rewrite':
    ensure => present,
  }
  httpd_mod { 'proxy':
    ensure => present,
  }
  httpd_mod { 'proxy_http':
    ensure => present,
  }
}
