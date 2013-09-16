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
  $site_file_owner = 'root',
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
    command     => "drupal-site-deploy.sh -in /etc/drupal_site/${site_name}.config",
    creates     => $site_deploy_flagfile,
    timeout     => $site_deploy_timeout,
    require     => [ File["/etc/drupal_site/${site_name}.config"],
      File['/usr/local/sbin/drupal-site-deploy.sh'] ],
  }

}
