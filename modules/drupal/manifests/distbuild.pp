# Copyright 2013  OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
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
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { $site_staging_root:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  vcsrepo { "${site_sandbox_root}/${site_build_repo_name}":
    ensure   => latest,
    provider => git,
    revision => $site_repo_branch,
    source   => $site_repo_url,
  }

  exec { 'drupal-build-dist':
    path      => '/usr/bin:/bin',
    timeout   => 900,
    cwd       => "${site_sandbox_root}/${$site_build_repo_name}",
    command   => "rm -rf ${site_staging_root}/${site_staging_tarball} && drush make --tar ${site_makefile} ${site_staging_root}/${site_staging_tarball}",
    unless    => "diff ${site_sandbox_root}/${$site_build_repo_name}/.git/refs/heads/master ${site_build_flagfile}",
    require   => File[$site_staging_root],
    subscribe => Vcsrepo["${site_sandbox_root}/${$site_build_repo_name}"],
  }

  exec { 'drupal-build-dist-post':
    path      => '/usr/bin:/bin',
    command   => "cp ${site_sandbox_root}/${$site_build_repo_name}/.git/refs/heads/master ${site_build_flagfile} && rm -rf ${site_deploy_flagfile}",
    unless    => "diff ${site_sandbox_root}/${$site_build_repo_name}/.git/refs/heads/master ${site_build_flagfile}",
    subscribe => Vcsrepo["${site_sandbox_root}/${$site_build_repo_name}"],
    require   => Exec['drupal-build-dist'],
  }
}
