# PRIVATE CLASS - do not use directly
class puppetdb::server::database_ini(
  $database          = $puppetdb::params::database,
  $database_host     = $puppetdb::params::database_host,
  $database_port     = $puppetdb::params::database_port,
  $database_username = $puppetdb::params::database_username,
  $database_password = $puppetdb::params::database_password,
  $database_name     = $puppetdb::params::database_name,
  $database_ssl      = $puppetdb::params::database_ssl,
  $node_ttl          = $puppetdb::params::node_ttl,
  $node_purge_ttl    = $puppetdb::params::node_purge_ttl,
  $report_ttl        = $puppetdb::params::report_ttl,
  $gc_interval       = $puppetdb::params::gc_interval,
  $log_slow_statements = $puppetdb::params::log_slow_statements,
  $conn_max_age      = $puppetdb::params::conn_max_age,
  $conn_keep_alive   = $puppetdb::params::conn_keep_alive,
  $conn_lifetime     = $puppetdb::params::conn_lifetime,
  $confdir           = $puppetdb::params::confdir,
) inherits puppetdb::params {

  # Validate the database connection.  If we can't connect, we want to fail
  # and skip the rest of the configuration, so that we don't leave puppetdb
  # in a broken state.
  class { 'puppetdb::server::validate_db':
    database          => $database,
    database_host     => $database_host,
    database_port     => $database_port,
    database_username => $database_username,
    database_password => $database_password,
    database_name     => $database_name,
  }

  #Set the defaults
  Ini_setting {
    path    => "${confdir}/database.ini",
    ensure  => present,
    section => 'database',
    require => Class['puppetdb::server::validate_db'],
  }

  if $database == 'embedded'{

    $classname   = 'org.hsqldb.jdbcDriver'
    $subprotocol = 'hsqldb'
    $subname     = $puppetdb::params::embedded_subname

  } elsif $database == 'postgres' {
    $classname = 'org.postgresql.Driver'
    $subprotocol = 'postgresql'

    $subname = $database_ssl ? {
      true    => "//${database_host}:${database_port}/${database_name}?ssl=true",
      default => "//${database_host}:${database_port}/${database_name}",
    }

    ##Only setup for postgres
    ini_setting {'puppetdb_psdatabase_username':
      setting => 'username',
      value   => $database_username,
    }

    if $database_password != undef {
      ini_setting {'puppetdb_psdatabase_password':
        setting => 'password',
        value   => $database_password,
      }
    }
  }

  ini_setting {'puppetdb_classname':
    setting => 'classname',
    value   => $classname,
  }

  ini_setting {'puppetdb_subprotocol':
    setting => 'subprotocol',
    value   => $subprotocol,
  }

  ini_setting {'puppetdb_pgs':
    setting => 'syntax_pgs',
    value   => true,
  }

  ini_setting {'puppetdb_subname':
    setting => 'subname',
    value   => $subname,
  }

  ini_setting {'puppetdb_gc_interval':
    setting => 'gc-interval',
    value   => $gc_interval,
  }

  ini_setting {'puppetdb_node_ttl':
    setting => 'node-ttl',
    value   => $node_ttl,
  }

  ini_setting {'puppetdb_node_purge_ttl':
    setting => 'node-purge-ttl',
    value   => $node_purge_ttl,
  }

  ini_setting {'puppetdb_report_ttl':
    setting => 'report-ttl',
    value   => $report_ttl,
  }

  ini_setting {'puppetdb_log_slow_statements':
    setting => 'log-slow-statements',
    value   => $log_slow_statements,
  }

  ini_setting {'puppetdb_conn_max_age':
    setting => 'conn-max-age',
    value   => $conn_max_age,
  }

  ini_setting {'puppetdb_conn_keep_alive':
    setting => 'conn-keep-alive',
    value   => $conn_keep_alive,
  }

  ini_setting {'puppetdb_conn_lifetime':
    setting => 'conn-lifetime',
    value   => $conn_lifetime,
  }
}
