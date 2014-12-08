# Class: askbot::site
#
# This class installs an Askbot site.
#
# Parameters:
#   - $slot_name: slot name under /srv/askbot-sites
#     (Notice: don't use ask as a slot name)
#   - $www_group: group name for web writeable directories like upfiles and log
#   - $www_user: user name for web process
#   - $askbot_debug: set to true to enable askbot debug mode
#
#   Custom askbot theme settings:
#   - $custom_theme_enabled: set to true to enable custom themes, default: false
#   - $custom_theme_name: name of custom theme set to default
#
#   Redis configuration:
#   - $redis_enabled: set to true to use redis as cache backend
#   - $redis_prefix: redis key prefix (required for multi-site setups)
#   - $redis_port: port of redis service
#   - $redis_max_memory: memory allocation for redis
#   - $redis_bind: bind address of redis service
#   - $redis_password: password required for redis connection
#
#   SSL Settings:
#   - $site_ssl_enabled: set to true for SSL based vhost
#   - $site_ssl_cert_file_contents: x509 certificate in pem format
#   - $site_ssl_key_file_contents: the key of site certificate in pem format
#   - $site_ssl_chain_file_contents: the issuer certs of site cert (optional)
#   - $site_ssl_cert_file: file name of site certificate
#   - $site_ssl_key_file: file name of the site certificate's key file
#   - $site_ssl_chain_file: file name of the issuer certificates
#
#   Email configuration:
#   - $smtp_host: hostname of smtp service used for email sending
#   - $smtp_port: port of smtp service
#
#   Database provider and connection details:
#   - $db_provider: database provider (mysql or pgsql)
#   - $db_name: database name
#   - $db_user: user name required for db connection
#   - $db_password: password required for db connection
#   - $db_host: database host
#
# Actions:
#   - Install an Askbot site
#   - Sync and migrate database schema
#   - Install askbot-celeryd daemon
#   - Setup log rotatation for application logs
#
define askbot::site (
  $www_user  = 'www-data',
  $www_group = 'www-data',
  $slot_name = 'slot0',
  $custom_theme_enabled = false,
  $custom_theme_name = undef,
  $askbot_debug = false,
  $redis_enabled = false,
  $redis_prefix = 'askbot',
  $redis_port = undef,
  $redis_max_memory = undef,
  $redis_bind = undef,
  $redis_password = undef,
  $site_ssl_enabled = false,
  $site_ssl_cert_file_contents = undef,
  $site_ssl_key_file_contents = undef,
  $site_ssl_chain_file_contents = undef,
  $site_ssl_cert_file = '',
  $site_ssl_key_file = '',
  $site_ssl_chain_file = '',
  $smtp_host = 'localhost',
  $smtp_port = '25',
  $db_provider = 'mysql',
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $db_host = 'localhost',
) {
  # ensure askbot base class is included
  if ! defined(Class['askbot']) {
    fail('You must include the askbot base class before using any askbot defined resources')
  }

  case $db_provider {
    'mysql': {
      $db_engine = 'django.db.backends.mysql'
    }
    'pgsql': {
      $db_engine = 'django.db.backends.postgresql_psycopg2'
    }
    default: {
      fail("Unsupported database provider: ${db_provider}")
    }
  }

  $askbot_site_root = "/srv/askbot-sites/${slot_name}"

  # ssl certificates
  if $site_ssl_enabled == true {

    include apache::ssl

    # site x509 certificate
    if $site_ssl_cert_file_contents != '' {
      file { $site_ssl_cert_file:
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => $site_ssl_cert_file_contents,
        before  => Apache::Vhost[$name],
      }
    }

    # site ssl key
    if $site_ssl_key_file_contents != '' {
      file { $site_ssl_key_file:
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => $site_ssl_key_file_contents,
        before  => Apache::Vhost[$name],
      }
    }

    # site ca certificates file
    if $site_ssl_chain_file_contents != '' {
      file { $site_ssl_chain_file:
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => $site_ssl_chain_file_contents,
        before  => Apache::Vhost[$name],
      }
    }
  }

  # site directory layout
  if ! defined(File[$askbot_site_root]) {
    file { $askbot_site_root:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }

  file { "${askbot_site_root}/log":
    ensure  => directory,
    owner   => 'root',
    group   => $www_group,
    mode    => '0775',
    require => File[$askbot_site_root],
  }

  # if not exists, create empty log file with
  # www-data group write access
  file { "${askbot_site_root}/log/askbot.log":
    ensure  => present,
    replace => 'no',
    owner   => 'root',
    group   => $www_group,
    mode    => '0664',
    require => File["${askbot_site_root}/log"],
  }

  file { "${askbot_site_root}/upfiles":
    ensure  => directory,
    owner   => 'root',
    group   => $www_group,
    mode    => '0775',
    require => File[$askbot_site_root],
  }

  file { "${askbot_site_root}/static":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$askbot_site_root],
  }

  file { "${askbot_site_root}/config":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$askbot_site_root],
  }

  # askbot setup_templates
  # copy template files from askbot's setup_templates into site config
  $setup_templates = [ '__init__.py', 'manage.py', 'urls.py', 'django.wsgi']
  askbot::template_file { $setup_templates:
    template_path => '/usr/local/lib/python2.7/dist-packages/askbot/setup_templates',
    dest_dir      => "${askbot_site_root}/config",
    require       => File["${askbot_site_root}/config"],
  }

  # askbot settings
  file { "${askbot_site_root}/config/settings.py":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('askbot/settings.py.erb'),
    require => File["${askbot_site_root}/config"],
  }

  # post-configuration
  Exec {
    path => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    logoutput => on_failure,
  }

  $post_config_dependency = [
      File["${askbot_site_root}/static"],
      File["${askbot_site_root}/log"],
      Askbot::Template_file[ $setup_templates ],
      File["${askbot_site_root}/config/settings.py"],
      Package['askbot'],
    ]

  exec { "askbot-static-generate-${slot_name}":
    cwd         => "${askbot_site_root}/config",
    command     => 'python manage.py collectstatic --noinput',
    require     => $post_config_dependency,
    subscribe   => File["${askbot_site_root}/config/settings.py"],
    refreshonly => true,
  }

  exec { "askbot-syncdb-${slot_name}":
    cwd         => "${askbot_site_root}/config",
    command     => 'python manage.py syncdb --noinput',
    require     => $post_config_dependency,
    subscribe   => File["${askbot_site_root}/config/settings.py"],
    refreshonly => true,
  }

  exec { "askbot-migrate-${slot_name}":
    cwd         => "${askbot_site_root}/config",
    command     => 'python manage.py migrate --noinput',
    require     => Exec["askbot-syncdb-${slot_name}"],
    subscribe   => File["${askbot_site_root}/config/settings.py"],
    refreshonly => true,
    notify      => [ Service['httpd'], Service['askbot-celeryd'] ],
  }

  apache::vhost { $name:
    port     => 80,
    priority => 10,
    docroot  => $askbot_site_root,
    require  => Exec["askbot-migrate-${slot_name}"],
    template => 'askbot/askbot.vhost.erb',
  }

  file { '/etc/init/askbot-celeryd.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('askbot/celeryd.upstart.conf.erb'),
    require => Exec["askbot-migrate-${slot_name}"],
  }

  service { 'askbot-celeryd':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init/askbot-celeryd.conf'],
  }

  include logrotate
  logrotate::file { "askbot-${slot_name}.log":
    log     => "${askbot_site_root}/askbot.log",
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => [ Service['httpd'], File["${askbot_site_root}/log/askbot.log"] ],
  }

}