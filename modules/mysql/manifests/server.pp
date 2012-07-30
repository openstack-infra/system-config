# installs mysql-server, configures app armor 
# and my.cnf, starts mysqld.
#
# Most of these defaults are from the
# debian install + the default .deb my.cnf
class mysql::server(
  $version                        = "5.5",
  $datadir                        = "/var/lib/mysql",
  $port                           = 3306,
  $bind_address                   = "127.0.0.1",
  $socket                         = "/var/run/mysqld/mysqld.sock",
  $pid                            = "/var/run/mysqld/mysqld.pid",
  # logging
  $log_error                      = "/var/log/mysql/mysql.err",
  $slow_query_log_file            = false,
  $long_query_time                = 10,
  $basedir                        = "/usr",
  $tmpdir                         = "/tmp",

  # Buffers, Threads, Caches, Limits
  $tmp_table_size                 = '16M',
  $max_heap_table_size            = '16M',
  $max_tmp_tables                 = '32',

  $join_buffer_size               = '3M',
  $read_buffer_size               = '4M',
  $sort_buffer_size               = '4M',

  $table_cache                    = '64',
  $table_definition_cache         = '256',
  $open_files_limit               = '1024',

  $thread_stack                   = '192K',
  $thread_cache_size              = '8',
  $thread_concurrency             = '10',

  $query_cache_size               = '16M',
  $query_cache_limit              = '1M',
  $tmp_table_size                 = '16M',
  $read_rnd_buffer_size           = '256K',

  $default_engine                 = 'UNSET',

  $ssl_ca
  $ssl_cert
  $ssl_key

  $key_buffer_size                = '16M',
  $myisam_sort_buffer_size        = '8M',
  $myisam_max_sort_file_size      = '512M',
  $myisam_recover                 = 'BACKUP',

  # Networking
  $max_allowed_packet             = "16M",
  $max_connections                = '151',
  $wait_timeout                   = "28800",
  $connect_timeout                = "10",

  # InnoDB settings.
  $innodb_file_per_table          = '1',
  $innodb_status_file             = '0',
  $innodb_support_xa              = '0',
  $innodb_flush_log_at_trx_commit = '0',
  $innodb_buffer_pool_size        = '8M',
  $innodb_log_file_size           = '5M',
  $innodb_flush_method            = 'O_DIRECT',
  $innodb_thread_concurrency      = '8',
  $innodb_concurrency_tickets     = '500',
  $innodb_doublewrite             = '1',

  # set read_only to true if you want this instance to be read_only
  $read_only                      = false,

  # set replication_enabled to false if you don't want to enable binary logging
  $replication_enabled            = false,
  # These settings won't matter if replication_enabled is false.

  $expire_logs_days               = '10',
  $max_binlog_size                = '100M',
  $replicate_ignore_table         = [],
  $replicate_ignore_db            = [],
  $replicate_do_table             = [],
  $replicate_do_db                = [],

  $extra_configs                  = {},
  $config_file_path               = "/etc/mysql/my.cnf"
  )
{
  # make sure mysql-server and mysql-client are
  # installed with the specified version.
  class { "mysql::packages::server": version => $version }
  class { "mysql::packages::client": version => $version }
  include apparmor

  # ensure the datadir exists
  file { $datadir:
    owner => "mysql",
    group => "mysql",
    mode  => 0755,
    ensure => "directory",
    require => Package["mysql-server"],
  }

  # Put my.cnf in place from the generic_my.cnf.erb template.
  # The values in this file are filled in from the 
  # passed in parameters.
  file { $config_file_path:
    owner => 'root',
    group => 'root',
    mode  => 0644,
    content => template('mysql/generic_my.cnf.erb'),
    require => [Package["mysql-server"], File["/etc/apparmor.d/usr.sbin.mysqld"]],
  }

  # mysql is protected by apparmor.  Need to
  # reload apparmor if the file changes.
  file { "/etc/apparmor.d/usr.sbin.mysqld":
    owner => 'root',
    group => 'root',
    mode => 0644,
    content => template('mysql/apparmor.usr.sbin.mysqld.erb'),
    require => Package["mysql-server"],
    notify => Service["apparmor"],
  }

  service { "mysql":
    ensure => "running",
    require => [Package["mysql-server"], File[$config_file_path, "/etc/apparmor.d/usr.sbin.mysqld"]],
    # don't subscribe mysql to its config files.
    # it is better to be able to restart mysql
    # manually when you intend for it to happen,
    # rather than allowing puppet to do it without
    # your supervision.
  }
}
