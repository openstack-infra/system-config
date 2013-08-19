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
) {
  exec { 'drupal-extract-tarball':
    path        => '/usr/bin:/bin',
    cwd         => $site_docroot,
    command     => "tar xfz ${site_staging_root}/${$site_staging_tarball} \
      --strip-components=1",
    creates     => $site_deploy_flagfile,
  }

  exec { 'drupal-create-config':
    path        => '/usr/bin:/bin',
    cwd         => $site_docroot,
    command     => 'cp sites/default/default.settings.php \
      sites/default/settings.php',
    creates     => $site_deploy_flagfile,
    require     => Exec['drupal-extract-tarball'],
  }

  exec { 'drupal-bulk-set-permissions':
    path        => '/usr/bin:/bin',
    cwd         => $site_docroot,
    command     => "chown -R nobody:www-data * &&
      find * -type d -exec chmod 0755 {} \\;&& \
      find * -type f -exec chmod 0644 {} \\;",
    creates     => $site_deploy_flagfile,
    require     => Exec['drupal-create-config'],
  }

  file { "${site_docroot}/sites/default/settings.php":
    ensure  => file,
    mode    => '0664',
    require => Exec['drupal-bulk-set-permissions'],
  }

  file { "${site_docroot}/sites/default/files":
    ensure  => directory,
    owner   => 'nobody',
    group   => 'www-data',
    mode    => '0775',
    require => Exec['drupal-bulk-set-permissions'],
  }

  exec { 'drupal-site-install':
    path        => '/usr/bin:/bin',
    cwd         => $site_docroot,
    command     => "drush si -y ${site_profile} --db-url=mysql://${$site_mysql_user}:${site_mysql_password}@${site_mysql_host}/${$site_mysql_database}",
    creates     => $site_deploy_flagfile,
    require     => [ File["${site_docroot}/sites/default/settings.php"],
      File["${site_docroot}/sites/default/files"],
      Exec['drupal-bulk-set-permissions']
    ],
  }

  exec { 'drupal-site-post-install-sitename':
    path        => '/usr/bin:/bin',
    cwd         => $site_docroot,
    command     => "drush vset site_name ${site_name}",
    creates     => $site_deploy_flagfile,
    require     => Exec['drupal-site-install'],
  }

  exec { 'drupal-site-post-install-admin-password':
    path        => '/usr/bin:/bin',
    cwd         => $site_docroot,
    command     => "drush upwd admin --password=\"${site_admin_password}\"",
    creates     => $site_deploy_flagfile,
    require     => Exec['drupal-site-install'],
  }

  exec { 'drupal-site-post-install-done':
    path        => '/usr/bin:/bin',
    command     => "touch ${site_deploy_flagfile}",
    creates     => $site_deploy_flagfile,
    require     => Exec['drupal-site-post-install-admin-password'],
  }
}
