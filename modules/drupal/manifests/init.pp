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
# - Install Drush tool with Drush-dsd extension
# - Fetch distribution tarball from remote repository
# - Deploy dist tarball and setup Drupal from scratch or
#   upgrade an existing site.
#
# Site parameters:
# - site_name: name of the site (FQDN for example)
# - site_admin_password: password of drupal admin
# - site_docroot: root directory of drupal site
# - site_vhost_root: root directory of virtual hosts
# - site_create_database: if true, create a new database (default: false)
# - site_alias: drush site alias name
# - site_profile: installation profile to deploy
#
# Mysql connection:
# - mysql_user: mysql user of drupal site
# - mysql_password: password of site user
# - mysql_database: site database name
# - mysql_host: host of mysql server (default: localhost)
#
# Drupal configuration variables:
# - conf_cron_key: cron_key setting used for cron access
#
# Remarks:
# - the site lives in /srv/vhosts/{hostname}/slot0 or slot1 directory
# - the /srv/vhosts/{hostname}/w symlinks to slot0 or slot1 and
#   points to actual site root. The upgrade process will begin in
#   inactive slot so we can avoid typical WSOD issues with Drupal.
# - for temporary package/tarball download it is using the
#   /srv/downloads directory.
#

class drupal (
  $site_name = undef,
  $site_root = undef,
  $site_docroot = "${site_root}/w",
  $site_mysql_host = 'localhost',
  $site_mysql_user = undef,
  $site_mysql_password = undef,
  $site_mysql_database = undef,
  $site_vhost_root = '/srv/vhosts',
  $site_profile = 'standard',
  $site_admin_password = undef,
  $site_alias = undef,
  $site_create_database = false,
  $site_base_url = false,
  $site_file_owner = 'root',
  $package_repository = undef,
  $package_branch = undef,
  $conf_cron_key = undef,
  $conf_markdown_directory = undef,
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
    require  => Exec['init-slot-dirs'],
    template => 'drupal/drupal.vhost.erb',
  }

  file { $site_root:
    ensure  => directory,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0755',
    require => Package['httpd'],
  }

  # Create initial symlink here to allow apache vhost creation
  # so drush dsd can flip this symlink between slot0/slot1
  # (won't be recreated until the symlink exists)
  exec { 'init-slot-dirs':
    command   => "/bin/ln -s ${site_root}/slot1 ${site_docroot}",
    unless    => "/usr/bin/test -L ${site_docroot}",
    logoutput => 'on_failure',
    require   => File[$site_root],
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

  # This directory is used to download and cache tarball releases
  # without proper upstream packages
  file { '/srv/downloads':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # setup drush and drush-dsd extension
  drush { 'drush':
    require => File['/srv/downloads'],
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

  # drush site-alias definition

  file { '/etc/drush':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/drush/aliases.drushrc.php':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => template('drupal/aliases.drushrc.php.erb'),
    replace => true,
    require => [ File['/etc/drush'], Drush['drush'] ],
  }

  # site custom configuration

  file { "${site_root}/etc":
    ensure    => directory,
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
    require   => File[$site_root],
  }

  file { "${site_root}/etc/settings.php":
    ensure    => file,
    owner     => 'root',
    group     => 'root',
    mode      => '0400',
    content   => template('drupal/settings.php.erb'),
    replace   => true,
    require   => File["${site_root}/etc"],
  }

  # add site distro tarball from http repository including
  # md5 hash file
  exec { "download:${package_branch}.md5":
    command   => "/usr/bin/wget --timestamping ${package_repository}/${package_branch}.md5 -O /tmp/${package_branch}.md5",
    logoutput => 'on_failure',
    cwd       => '/tmp'
  }

  file { "/srv/downloads/${package_branch}.md5":
    ensure    => present,
    source    => "/tmp/${package_branch}.md5",
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    require   => [ Exec["download:${package_branch}.md5"], File['/srv/downloads'] ]
  }

  exec { "download:${package_branch}.tar.gz":
    command     => "/usr/bin/wget ${package_repository}/${package_branch}.tar.gz -O /srv/downloads/${package_branch}.tar.gz",
    logoutput   => 'on_failure',
    refreshonly => true,
    subscribe   => File["/srv/downloads/${package_branch}.md5"],
    require     => File['/srv/downloads'],
  }

  # deploy a site from scratch when site status is 'NOT INSTALLED'
  exec { "sitedeploy-${site_name}":
    command     => "/usr/bin/drush dsd-init @${site_alias} /srv/downloads/${package_branch}.tar.gz",
    logoutput   => true,
    timeout     => 600,
    onlyif      => "/usr/bin/drush dsd-status @${site_alias} | /bin/grep -c 'NOT INSTALLED'",
    refreshonly => true,
    subscribe   => File["/srv/downloads/${package_branch}.md5"],
    require     => [
      Exec["download:${package_branch}.md5"],
      File['/etc/drush/aliases.drushrc.php'],
      ]
  }

  # update the site into a new slot when a remote update available
  exec { "siteupdate-${site_name}":
    command     => "/usr/bin/drush dsd-update @${site_alias} /srv/downloads/${package_branch}.tar.gz",
    logoutput   => true,
    timeout     => 600,
    onlyif      => "/usr/bin/drush dsd-status @${site_alias} | /bin/grep -c 'UPDATE'",
    refreshonly => true,
    subscribe   => File["/srv/downloads/${package_branch}.md5"],
    require     => [
      Exec["download:${package_branch}.md5"],
      File['/etc/drush/aliases.drushrc.php'],
      Exec["sitedeploy-${site_name}"],
      ]
  }

  # setup cron job

  cron { $site_name:
    name    => "${site_name}.cron",
    command => "wget -O - -q -t 1 ${$site_base_url}/cron.php?cron_key=${$conf_cron_key}",
    user    => root,
    minute  => '*/5',
    require => [
      Exec["sitedeploy-${site_name}"],
      ]
  }

}