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
class openstack_project::openstackid_dev (
  $site_admin_password = '',
  $id_mysql_host = '',
  $id_mysql_user = '',
  $id_mysql_password = '',
  $id_db_name = 'openstackid_dev',
  $ss_mysql_host = '',
  $ss_mysql_user = '',
  $ss_mysql_password = '',
  $ss_db_name = 'os_dev',
  $redis_port = '6378',
  $redis_max_memory = '1gb',
  $redis_bind = '127.0.0.1',
  $redis_password = '',
  $redis_version = '2.8.4',
  $id_recaptcha_public_key = '',
  $id_recaptcha_private_key = '',
  $id_recaptcha_template = '',
  $id_log_error_to_email = '',
  $id_log_error_from_email = '',
  $id_environment = 'dev',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $vhost_name = '',
  $serveradmin = '',
  $canonicalweburl = '',
  $session_cookie_domain = '',
  $app_url = '',
  $app_key = '',
  $email_driver = 'mail',
  $email_send_grid_api_key = '',
  $email_smtp_server = 'smtp.mailgun.org',
  $email_smtp_server_port = 587,
  $email_smtp_server_user = '',
  $email_smtp_server_password = '',
  $laravel_version = 5,
  $app_log_level = 'debug',
  $app_log_email_level = 'debug',
  $db_log_enabled = false,
  $banning_enabled = false,
  $app_debug = false,
  $app_locale = 'en',
  $curl_verify_ssl_cert = false,
  $curl_allow_redirect = false,
  $curl_timeout = 60,
  $assets_base_url = 'https://devbranch.openstack.org/',
  $cache_driver = 'redis',
  $session_driver = 'redis',
  $session_cookie_secure = false,
  $php_version = 5,
  $mysql_ssl_enabled = false,
  $mysql_ssl_ca_file = '/etc/mysql-client-ssl/ca-cert.pem',
  $mysql_ssl_ca_file_contents = '',
  $mysql_ssl_client_key_file = '/etc/mysql-client-ssl/client-key.pem',
  $mysql_ssl_client_key_file_contents = '',
  $mysql_ssl_client_cert_file = '/etc/mysql-client-ssl/client-cert.pem',
  $mysql_ssl_client_cert_file_contents = ''

) {

  class { 'openstack_project::server': }

  class { 'openstackid':
    site_admin_password                 => $site_admin_password,
    id_mysql_host                       => $id_mysql_host,
    id_mysql_user                       => $id_mysql_user,
    id_mysql_password                   => $id_mysql_password,
    id_db_name                          => $id_db_name,
    ss_mysql_host                       => $ss_mysql_host,
    ss_mysql_user                       => $ss_mysql_user,
    ss_mysql_password                   => $ss_mysql_password,
    ss_db_name                          => $ss_db_name,
    redis_port                          => $redis_port,
    redis_host                          => $redis_bind,
    redis_password                      => $redis_password,
    id_recaptcha_public_key             => $id_recaptcha_public_key,
    id_recaptcha_private_key            => $id_recaptcha_private_key,
    id_recaptcha_template               => $id_recaptcha_template,
    id_log_error_to_email               => $id_log_error_to_email,
    id_log_error_from_email             => $id_log_error_from_email,
    id_environment                      => $id_environment,
    ssl_cert_file                       => "/etc/ssl/certs/${::fqdn}.pem",
    ssl_key_file                        => "/etc/ssl/private/${::fqdn}.key",
    ssl_chain_file                      => '/etc/ssl/certs/intermediate.pem',
    ssl_cert_file_contents              => $ssl_cert_file_contents,
    ssl_key_file_contents               => $ssl_key_file_contents,
    ssl_chain_file_contents             => $ssl_chain_file_contents,
    vhost_name                          => $vhost_name,
    serveradmin                         => $serveradmin,
    canonicalweburl                     => $canonicalweburl,
    session_cookie_domain               => $session_cookie_domain,
    app_url                             => $app_url,
    app_key                             => $app_key,
    email_driver                        => $email_driver,
    email_send_grid_api_key             => $email_send_grid_api_key,
    email_smtp_server                   => $email_smtp_server,
    email_smtp_server_port              => $email_smtp_server_port,
    email_smtp_server_user              => $email_smtp_server_user,
    email_smtp_server_password          => $email_smtp_server_password,
    laravel_version                     => $laravel_version,
    app_log_level                       => $app_log_level,
    app_log_email_level                 => $app_log_email_level,
    db_log_enabled                      => $db_log_enabled,
    banning_enabled                     => $banning_enabled,
    app_debug                           => $app_debug,
    app_locale                          => $app_locale,
    curl_verify_ssl_cert                => $curl_verify_ssl_cert,
    curl_allow_redirect                 => $curl_allow_redirect,
    curl_timeout                        => $curl_timeout,
    assets_base_url                     => $assets_base_url,
    cache_driver                        => $cache_driver,
    session_driver                      => $session_driver,
    session_cookie_secure               => $session_cookie_secure,
    php_version                         => $php_version,
    mysql_ssl_enabled                   => $mysql_ssl_enabled,
    mysql_ssl_ca_file                   => $mysql_ssl_ca_file,
    mysql_ssl_ca_file_contents          => $mysql_ssl_ca_file_contents,
    mysql_ssl_client_key_file           => $mysql_ssl_client_key_file,
    mysql_ssl_client_key_file_contents  => $mysql_ssl_client_key_file_contents,
    mysql_ssl_client_cert_file          => $mysql_ssl_client_cert_file,
    mysql_ssl_client_cert_file_contents => $mysql_ssl_client_cert_file_contents,
  }

  # redis (custom module written by tipit)
  class { 'redis':
    redis_port       => $redis_port,
    redis_max_memory => $redis_max_memory,
    redis_bind       => $redis_bind,
    redis_password   => $redis_password,
    version          => $redis_version ,
  }

}
