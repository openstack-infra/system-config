# License

Copyright 2013  OpenStack Foundation
Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

# Drupal module for Puppet

This module manages Drupal on Linux distros.

## Description

## Usage

### drupal
Install and configure a Drupal site, including Apache vhost entry, MySQL
database, Pear and drush cli tool.

Example:

    class { 'drupal':
      site_name            => 'www.example.com',
      site_docroot         => '/srv/vhosts/example.com',
      site_mysql_host      => 'localhost',
      site_mysql_user      => 'myuser',
      site_mysql_password  => 's3cretPassw0rd',
      site_mysql_database  => 'example',
      site_vhost_root      => '/srv/vhosts',
      site_staging_tarball => 'example-dev.tar.gz',
      site_admin_password  => 'adminadmin',
      site_build_reponame  => 'example-master',
      site_makefile        => 'build-example.make',
      site_repo_url        => 'https://git.example.com/repo/example',
      site_profile         => 'standard',
      site_base_url        => 'http://example.com',
      ...
    }

Build process:
- build a distribution tarball (drupal::distbuild)
- deploy a site from scratch (drupal:sitedeploy)

### drupal::distbuild
Build a distribution from a git repository, using drush make command. Check
out the git repository under site_sandbox_root and compare head commit with
latest deployed version. If version is different, clean up the
site_deploy_flagfile, and drush make building process start. The flag file
site_build_flagfile always contains the version of built repository.

Example:

    distbuild { "distbuild-${site_name}":
      site_sandbox_root    => '/srv/sandbox',
      site_staging_root    => '/srv/sandbox/release',
      site_repo_url        => 'https://git.example.com/repo/example',
      site_build_repo_name => 'example-master',
      site_staging_tarball => 'example-dev.tar.gz',
      site_build_flagfile  => '/tmp/drupal-site-build',
      site_deploy_flagfile => '/tmp/drupal-site-deploy',
      site_makefile        => 'build-example.make',
      ...
    }

Directory structure:
    /srv/sandbox/example-master   local git repository clone
      build-example.make
      drupal-org-core.make
      drupal-org.make
      example.info
      example.install
      example.profile
    /srv/sandbox/release          distribution tarball directory
      example-dev.tar.gz

Flag files:
/tmp/drupal-site-build
Holds the version of information of latest successfull build
    # pack-refs with: peeled
    df23bc9510ac8406c33f896f824997a79d20d27d refs/remotes/origin/master

/tmp/drupal-site-deploy
If missing, drupal:sitedeploy triggers a new deployment process.

### drupal:sitedeploy
Deploy and install a new site based on a previously built distribution
tarball, using drupal_site_deploy.sh script.


Example:

    sitedeploy { "sitedeploy-${site_name}":
      site_docroot         => '/srv/vhosts/example.com',
      site_staging_root    => '/srv/sandbox/release',
      site_staging_tarball => 'example-dev.tar.gz',
      site_deploy_flagfile => '/tmp/drupal-site-deploy',
      site_name            => $site_name,
      site_profile         => 'standard',
      site_mysql_host      => 'localhost',
      site_mysql_user      => 'myuser',
      site_mysql_password  => 's3cretPassw0rd',
      site_mysql_database  => 'example',
      site_admin_password  => 'adminadmin',
      site_base_url        => 'http://example.com',
      ...
    }

Directory structure:
    /srv/vhosts/example.com   drupal site root
    /etc/drupal
      example.com.config      drupal site deploy script configuration

