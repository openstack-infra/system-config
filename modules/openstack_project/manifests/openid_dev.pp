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
# openstackid idp(sso-openid) dev server
#
class openstack_project::openid_dev (
  $mysql_root_password = '',
  $site_admin_password = '',
  $site_mysql_password = '',
  $sysadmins = [],
  $db_name  = 'openstackid_openid',
  $certname = '',
  $redis_port='6378',
  $redis_max_memory ='1gb',
  $redis_bind ='127.0.0.1',
) {
  realize (
    User::Virtual::Localuser['smarcet'],
  )

  #mysql http://forge.puppetlabs.com/puppetlabs/mysql - puppet module install puppetlabs/mysql
  class { 'mysql::server':
    root_password => $mysql_root_password,
  }

  mysql_database { 
    $db_name:
    ensure  => present,
    charset => 'utf8',
    #collate => 'utf8_unicode_ci',
    require => Class['mysql::server'],
  }

  #php
  package { ["php5-common","php5-curl","php5-cli","php5-json","php5-mcrypt","php5-mysql"]:
    ensure => installed,
  }
  # redis (custom module writed by tipit)

  class { 'redis':
    redis_port => $redis_port,
    redis_max_memory=> $redis_max_memory,
    redis_bind=>$redis_bind,
  }
  # apache (http://forge.puppetlabs.com/puppetlabs/apache)
  # Base class. Turn off the default vhosts; we will be declaring
  # all vhosts below.
  class { 'apache':
    default_vhost => false,
    mpm_module => 'prefork',
  }

  apache::listen { '80': }
  apache::listen { '443': }
  include apache::mod::ssl
  include apache::mod::php
  #create directory for virtual host
  file { "/var/www/openstackid_idp":
    ensure => directory,
    require => Package["apache2"],
    }
  # SSL vhost
  # apache::vhost { 'dev.openstackid.com ssl':
  #  servername => 'dev.openstackid.com',
  #  port       => '443',
  #  docroot    => '/var/www/openstackid_idp',
  #  ssl        => true,
  #need certs
  #  ssl_cert => $certname,
  #  ssl_key  => '',
  #}

}
