# == Define: sitedeploy
#
# define to deploy drupal site from distribution tarball
#
define drupal::sitedeploy (
  $site_docroot = undef,
  $site_staging_root = undef,
  $site_staging_tarball = undef,
  $site_deploy_flagfile = undef,
  $site_name = undef,
  $site_profile = undef,
  $site_mysql_user = undef,
  $site_mysql_password = undef,
  $site_mysql_host = undef,
  $site_mysql_database = undef,
  $site_admin_password = '',
  $site_deploy_timeout = 600,
  $site_base_url = undef,
) {
  file { '/usr/local/sbin/drupal-site-deploy.sh':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0744',
    source => 'puppet:///modules/drupal/drupal_site_deploy.sh',
  }

  file { '/etc/drupal_site':
    ensure => directory,
  }

  file { "/etc/drupal_site/${site_name}.config":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => template('drupal/site.config.erb'),
    replace => true,
    require => File['/etc/drupal_site'],
  }

  exec { "drupal-deploy-${site_name}":
    path        => '/usr/bin:/bin:/usr/local/sbin',
    command     => "drupal-site-deploy.sh -in /etc/drupal_site/${site_name}.\
config",
    creates     => $site_deploy_flagfile,
    timeout     => $site_deploy_timeout,
    require     => [ File["/etc/drupal_site/${site_name}.config"],
      File['/usr/local/sbin/drupal-site-deploy.sh'] ],
  }

}
