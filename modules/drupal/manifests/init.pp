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
# == Class: drupal
#
# A wrapper class to support drupal project integration based on LAMP
# environment.
#
# Actions:
# - Prepare apache vhost and create mysql database (optional)
# - Build distribution tarball from git repo as a soruce
# - Deploy dist tarball and setup Drupal from scratch
#
# Site parameters:
# - site_name: name of the site (FQDN for example)
# - site_admin_password: password of drupal admin
# - site_docroot: root directory of drupal site
# - site_vhost_root: root directory of virtual hosts
# - site_create_database: if true, create a new database (default: false)
#
# Mysql connection:
# - mysql_user: mysql user of drupal site
# - mysql_password: password of site user
# - mysql_database: site database name
# - mysql_host: host of mysql server (default: localhost)
#
# Distribution build process:
# - site_sandbox_root: root directory of sandbox where build happens
# - site_staging_root: root directory of target tarballs
# - site_staging_tarball: target tarball of build process
# - site_makefile: installation profile drush makefile
# - site_build_reponame: local repository name under sandbox root
# - site_repo_url: git repo url of installation profile source
# - site_build_flagfile: triggers a rebuild when missing or git head differs
#
# Deploy process:
# - site_profile: installation profile to deploy
# - site_deploy_flagfile: triggers a redeploy when this flagfile is missing

class drupal (
  $site_name = undef,
  $site_docroot = undef,
  $site_mysql_host = 'localhost',
  $site_mysql_user = undef,
  $site_mysql_password = undef,
  $site_mysql_database = undef,
  $site_vhost_root = '/srv/vhosts',
  $site_sandbox_root = '/srv/sandbox',
  $site_staging_root = '/srv/sandbox/release',
  $site_staging_tarball = '',
  $site_profile = 'standard',
  $site_admin_password = undef,
  $site_build_reponame = undef,
  $site_makefile = undef,
  $site_repo_url = undef,
  $site_build_flagfile = '/tmp/drupal-site-build',
  $site_deploy_flagfile = '/tmp/drupal-site-deploy',
  $site_create_database = false,
  $site_base_url = false,
) {
  include apache
  include pear

  # setup apache and virtualhosts, enable mod rewrite
  file { $site_vhost_root:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  apache::vhost { $site_name:
    port     => 80,
    priority => '50',
    docroot  => $site_docroot,
    require  => File[$site_docroot],
    template => 'drupal/drupal.vhost.erb',
  }

  file { $site_docroot:
    ensure  => directory,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0755',
    require => Package['httpd'],
  }

  a2mod { 'rewrite':
    ensure => present,
  }

  # php packages
  $drupal_related_packages = [ 'unzip', 'php5-mysql', 'php5-gd', 'php5-cli',
    'libapache2-mod-php5', 'mysql-client' ]

  package { $drupal_related_packages:
    ensure  => 'installed',
    require => Package['httpd'],
    notify  => Service['httpd'],
  }

  # pear / drush cli tool
  pear::package { 'PEAR': }
  pear::package { 'Console_Table': }
  pear::package { 'drush':
      version    => '5.9.0',
      repository => 'pear.drush.org',
      require    => Pear::Package['PEAR'],
  }

  # site mysql database
  if $site_create_database == true {
    mysql::db { $site_mysql_database:
      user     => $site_mysql_user,
      password => $site_mysql_password,
      host     => $site_mysql_host,
      grant    => ['all'],
      notify   => Distbuild["distbuild-${site_name}"],
    }
  }

  # drupal dist-build
  distbuild { "distbuild-${site_name}":
    site_sandbox_root    => $site_sandbox_root,
    site_staging_root    => $site_staging_root,
    site_repo_url        => $site_repo_url,
    site_build_repo_name => $site_build_reponame,
    site_staging_tarball => $site_staging_tarball,
    site_build_flagfile  => $site_build_flagfile,
    site_deploy_flagfile => $site_deploy_flagfile,
    site_makefile        => $site_makefile,
    require              => Package['httpd'],
  }

  # drupal site deploy
  sitedeploy { "sitedeploy-${site_name}":
    site_docroot         => $site_docroot,
    site_staging_root    => $site_staging_root,
    site_staging_tarball => $site_staging_tarball,
    site_deploy_flagfile => $site_deploy_flagfile,
    site_name            => $site_name,
    site_profile         => $site_profile,
    site_mysql_user      => $site_mysql_user,
    site_mysql_password  => $site_mysql_password,
    site_mysql_host      => $site_mysql_host,
    site_mysql_database  => $site_mysql_database,
    site_admin_password  => $site_admin_password,
    site_base_url        => $site_base_url,
    require              => Distbuild["distbuild-${site_name}"],
  }

}
