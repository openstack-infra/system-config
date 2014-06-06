# Copyright (c) 2014 Mirantis Inc.
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

# == Class: storyboard
#
# This class will install a fully functional standalone instance of
# storyboard on the current instance. It includes database setup and
# a set of sane configuration defaults. For more precise configuration,
# please use individual submodules.
#
class storyboard (
  $mysql_database           = 'storyboard',
  $mysql_user               = 'storyboard',
  $mysql_user_password      = 'changeme',

  $rabbitmq_user            = 'storyboard',
  $rabbitmq_user_password   = 'changemetoo',

  $hostname                 = $::fqdn,
  $openid_url               = 'https://login.launchpad.net/+openid',

  $ssl_cert_file            = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_cert_content         = undef,
  $ssl_key_file             = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_key_content          = undef,
  $ssl_ca_file              = undef,
  $ssl_ca_content           = undef
) {

  class { '::storyboard::cert':
    ssl_cert_file    => $ssl_cert_file,
    ssl_cert_content => $ssl_cert_content,
    ssl_key_file     => $ssl_key_file,
    ssl_key_content  => $ssl_key_content,
    ssl_ca_file      => $ssl_ca_file,
    ssl_ca_content   => $ssl_ca_content
  }

  class { '::storyboard::rabbit':
    rabbitmq_user          => $rabbitmq_user,
    rabbitmq_user_password => $rabbitmq_user_password
  }

  class { '::storyboard::mysql':
    mysql_database      => $mysql_database,
    mysql_user          => $mysql_user,
    mysql_user_password => $mysql_user_password
  }

  class { '::storyboard::application':
    hostname               => $hostname,
    openid_url             => $openid_url,
    mysql_host             => 'localhost',
    mysql_port             => 3306,
    mysql_database         => $mysql_database,
    mysql_user             => $mysql_user,
    mysql_user_password    => $mysql_user_password,

    rabbitmq_user          => $rabbitmq_user,
    rabbitmq_user_password => $rabbitmq_user_password
  }
}
