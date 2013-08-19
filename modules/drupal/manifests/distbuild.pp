# == Define: distbuild
#
# define to build distribution from git makefile
#
define drupal::distbuild (
  $site_sandbox_root = undef,
  $site_staging_root = undef,
  $site_repo_url = undef,
  $site_repo_branch = 'master',
  $site_build_repo_name = undef,
  $site_staging_tarball = undef,
  $site_build_flagfile = undef,
  $site_deploy_flagfile = undef,
  $site_makefile = undef,
) {
  file { $site_sandbox_root:
    ensure  => directory,
    owner   => 'nobody',
    group   => 'www-data',
  }

  file { $site_staging_root:
    ensure  => directory,
  }

  vcsrepo { "${site_sandbox_root}/${$site_build_repo_name}":
    ensure   => latest,
    provider => git,
    revision => $site_repo_branch,
    source   => $site_repo_url,
  }

  exec { 'drupal-build-dist':
    path    => '/usr/bin:/bin',
    timeout => 900,
    cwd     => "${site_sandbox_root}/${$site_build_repo_name}",
    command => "rm -rf ${site_staging_root}/${site_staging_tarball} && \
drush make --tar ${site_makefile} ${site_staging_root}/${site_staging_tarball}",
    unless  => "diff ${site_sandbox_root}/${$site_build_repo_name}/.git/\
packed-refs ${site_build_flagfile}",
    require => [ Vcsrepo["${site_sandbox_root}/${$site_build_repo_name}"],
      File[$site_staging_root] ]
  }

  exec { 'drupal-build-dist-post':
    path    => '/usr/bin:/bin',
    command => "cp ${site_sandbox_root}/${$site_build_repo_name}/.git/\
packed-refs ${site_build_flagfile} && rm -rf ${site_deploy_flagfile}",
    unless  => "diff ${site_sandbox_root}/${$site_build_repo_name}/.git/\
packed-refs ${site_build_flagfile}",
    require => Exec['drupal-build-dist'],
  }
}
