# Slave database configuration
class openstack_project::slave_db(
  $all_mysql_privs = false,
){

  include mysql::server::account_security

  mysql::db { 'openstack_citest':
    user     => 'openstack_citest',
    password => 'openstack_citest',
    host     => 'localhost',
    grant    => ['all'],
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }

  # mysql::db is too dumb to realize that the same user can have
  # access to multiple databases and will fail if you try creating
  # a second DB with the same user. Create the DB directly as mysql::db
  # above is creating the user for us.
  database { 'openstack_baremetal_citest':
    ensure   => present,
    charset  => 'utf8',
    provider => 'mysql',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }

  database_grant { 'openstack_citest@localhost/openstack_baremetal_citest':
    privileges => ['all'],
    provider   => 'mysql',
    require    => Database_user['openstack_citest@localhost'],
  }

  if ($all_mysql_privs == true) {
    database_grant { 'openstack_citest@localhost':
      privileges => ['all'],
      provider   => 'mysql',
      require    => Database_user['openstack_citest@localhost'],
    }
  }

  # Create DB user and explicitly make it non superuser
  # that can create databases.
  postgresql::server::role { 'openstack_citest':
    password_hash => postgresql_password('openstack_citest', 'openstack_citest'),
    createdb      => true,
    superuser     => false,
    require       => Class['postgresql::server'],
  }

  postgresql::server::db { 'openstack_citest':
    user     => 'openstack_citest',
    password => postgresql_password('openstack_citest', 'openstack_citest'),
    grant    => 'all',
    require  => [
      Class['postgresql::server'],
      Postgresql::Server::Role['openstack_citest'],
    ],
  }

  # Alter the new database giving the test DB user ownership of the DB.
  # This is necessary to make the nova unittests run properly.
  postgresql_psql { 'ALTER DATABASE openstack_citest OWNER TO openstack_citest':
    db          => 'postgres',
    refreshonly => true,
    subscribe   => Postgresql::Server::Db['openstack_citest'],
  }

  postgresql::server::db { 'openstack_baremetal_citest':
    user     => 'openstack_citest',
    password => postgresql_password('openstack_citest', 'openstack_citest'),
    grant    => 'all',
    require  => [
      Class['postgresql::server'],
      Postgresql::Server::Role['openstack_citest'],
    ],
  }

  # Alter the new database giving the test DB user ownership of the DB.
  # This is necessary to make the nova unittests run properly.
  postgresql_psql { 'ALTER DATABASE openstack_baremetal_citest OWNER TO
                     openstack_citest':
    db          => 'postgres',
    refreshonly => true,
    subscribe   => Postgresql::Server::Db['openstack_baremetal_citest'],
  }

}
# vim:sw=2:ts=2:expandtab:textwidth=79
