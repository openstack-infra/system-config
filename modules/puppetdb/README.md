puppetdb
=========

####Table of Contents

1. [Overview - What is the PuppetDB module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with PuppetDB module](#setup)
4. [Upgrading - Guide for upgrading from older revisions of this module](#upgrading)
4. [Usage - The classes and parameters available for configuration](#usage)
5. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------
By guiding puppetdb setup and configuration with a puppet master, the PuppetDB module provides fast, streamlined access to data on puppetized infrastructure.

Module Description
-------------------
The PuppetDB module provides a quick way to get started using PuppetDB, an open source inventory resource service that manages storage and retrieval of platform-generated data. The module will install PostgreSQL and PuppetDB if you don't have them, as well as set up the connection to puppet master. The module will also provide a dashboard you can use to view the current state of your system.

For more information about PuppetDB [please see the official PuppetDB documentation.](http://docs.puppetlabs.com/puppetdb/)


Setup
-----

**What PuppetDB affects:**

* package/service/configuration files for PuppetDB
* package/service/configuration files for PostgreSQL (optional, but set as default)
* puppet master's runtime (via plugins)
* puppet master's configuration
  * **note**: Using the `puppetdb::master::config` class will cause your routes.yaml file to be overwritten entirely (see **Usage** below for options and more information )
* system firewall (optional)
* listened-to ports

**Introductory Questions**

To begin using PuppetDB, you’ll have to make a few decisions:

* Which database back-end should I use?
  * PostgreSQL (default) or our embedded database
  * Embedded database
    * **note:** We suggest using the embedded database only for experimental environments rather than production, as it does not scale well and can cause difficulty in migrating to PostgreSQL.
* Should I run the database on the same node that I run PuppetDB on?
* Should I run PuppetDB on the same node that I run my master on?

The answers to those questions will be largely dependent on your answers to questions about your Puppet environment:

* How many nodes are you managing?
* What kind of hardware are you running on?
* Is your current load approaching the limits of your hardware?

Depending on your answers to all of the questions above, you will likely fall under one of these set-up options:

1. [Single Node (Testing and Development)](#single-node-setup)
2. [Multiple Node (Recommended)](#multiple-node-setup)

### Single Node Setup

This approach assumes you will use our default database (PostgreSQL) and run everything (PostgreSQL, PuppetDB, puppet master) all on the same node. This setup will be great for a testing or experimental environment. In this case, your manifest will look like:

    node puppetmaster {
      # Configure puppetdb and its underlying database
      class { 'puppetdb': }
      # Configure the puppet master to use puppetdb
      class { 'puppetdb::master::config': }
    }

You can provide some parameters for these classes if you’d like more control, but that is literally all that it will take to get you up and running with the default configuration.

### Multiple Node Setup

This approach is for those who prefer not to install PuppetDB on the same node as the puppet master. Your environment will be easier to scale if you are able to dedicate hardware to the individual system components. You may even choose to run the puppetdb server on a different node from the PostgreSQL database that it uses to store its data. So let’s have a look at what a manifest for that scenario might look like:

**This is an example of a very basic 3-node setup for PuppetDB.**

This node is our puppet master:

    node puppet {
      # Here we configure the puppet master to use PuppetDB,
      # and tell it that the hostname is ‘puppetdb’
      class { 'puppetdb::master::config':
        puppetdb_server => 'puppetdb',
      }
    }

This node is our postgres server:

    node puppetdb-postgres {
      # Here we install and configure postgres and the puppetdb
      # database instance, and tell postgres that it should
      # listen for connections to the hostname ‘puppetdb-postgres’
      class { 'puppetdb::database::postgresql':
        listen_addresses => 'puppetdb-postgres',
      }
    }

This node is our main puppetdb server:

    node puppetdb {
      # Here we install and configure PuppetDB, and tell it where to
      # find the postgres database.
      class { 'puppetdb::server':
        database_host => 'puppetdb-postgres',
      }
    }

This should be all it takes to get a 3-node, distributed installation of PuppetDB up and running. Note that, if you prefer, you could easily move two of these classes to a single node and end up with a 2-node setup instead.

### Beginning with PuppetDB
Whether you choose a single node development setup or a multi-node setup, a basic setup of PuppetDB will cause: PostgreSQL to install on the node if it’s not already there; PuppetDB postgres database instance and user account to be created; the postgres connection to be validated and, if successful, PuppetDB to be installed and configured; PuppetDB connection to be validated and, if successful, the puppet master config files to be modified to use PuppetDB; and the puppet master to be restarted so that it will pick up the config changes.

If your logging level is set to INFO or finer, you should start seeing PuppetDB-related log messages appear in both your puppet master log and your puppetdb log as subsequent agent runs occur.

If you’d prefer to use PuppetDB’s embedded database rather than PostgreSQL, have a look at the database parameter on the puppetdb class:

    class { 'puppetdb':
      database => 'embedded',
    }

The embedded database can be useful for testing and very small production environments, but it is not recommended for production environments since it consumes a great deal of memory as your number of nodes increase.

### Cross-node Dependencies

It is worth noting that there are some cross-node dependencies, which means that the first time you add the module's configurations to your manifests, you may see a few failed puppet runs on the affected nodes.

PuppetDB handles cross-node dependencies by taking a sort of “eventual consistency” approach. There’s nothing that the module can do to control the order in which your nodes check in, but the module can check to verify that the services it depends on are up and running before it makes configuration changes--so that’s what it does.

When your puppet master node checks in, it will validate the connectivity to the puppetdb server before it applies its changes to the puppet master config files. If it can’t connect to puppetdb, then the puppet run will fail and the previous config files will be left intact. This prevents your master from getting into a broken state where all incoming puppet runs fail because the master is configured to use a puppetdb server that doesn’t  exist yet. The same strategy is used to handle the dependency between the puppetdb server and the postgres server.

Hence the failed puppet runs. These failures should be limited to 1 failed run on the puppetdb node, and up to 2 failed runs on the puppet master node. After that, all of the dependencies should be satisfied and your puppet runs should start to succeed again.

You can also manually trigger puppet runs on the nodes in the correct order (Postgres, PuppetDB, puppet master), which will avoid any failed runs.

Upgrading
---------

###Upgrading from 2.x to version 3.x

For this release a major dependency has changed. The module `pupppetlabs/postgresql` must now be version 3.x. Upgrading the module should upgrade the `puppetlabs/postgresql` module for you, but if another module has a fixed dependency that module will have to be fixed before you can continue.

Some other changes include:

* The parameter `manage_redhat_firewall` for the class `puppetdb` has now been removed completely in favor of `open_postgres_port` and `open_ssl_listen_port`.
* The parameter `manage_redhat_firewall` for the class `puppetdb::database::postgresql`, has now been renamed to `manage_firewall`.
* The parameter `manage_redhat_firewall` for the class `puppetdb::server` has now been removed completely in favor of `open_listen_port` and `open_ssl_listen_port`.
* The internal class: `puppetdb::database::postgresql_db` has been removed. If you were using this, it is now defunct.
* The class `puppetdb::server::firewall` has been marked as private, do not use it directly.
* The class `puppetdb::server::jetty_ini` and `puppetdb::server::database_ini` have been marked as private, do not use it directly.

###Upgrading from 1.x to version 2.x

A major dependency has been changed, so now when you upgrade to 2.0 the dependency `cprice404/inifile` has been replaced with `puppetlabs/inifile`. This may interfer with other modules as they may depend on the old `cprice404/inifile` instead, so upgrading should be done with caution. Check that your other modules use the newer `puppetlabs/inifile` module as interoperation with the old `cprice404/inifile` module will no longer be supported by this module.

Depending on how you install your modules, changing the dependency may require manual intervention. Double check your modules contains the newer `puppetlabs/inifile` after installing this latest module.

Otherwise, all existing parameters from 1.x should still work correctly.

Usage
------

PuppetDB supports a large number of configuration options for both configuring the puppetdb service and connecting that service to the puppet master.

### puppetdb
The `puppetdb` class is intended as a high-level abstraction (sort of an 'all-in-one' class) to help simplify the process of getting your puppetdb server up and running. It wraps the slightly-lower-level classes `puppetdb::server` and `puppetdb::database::*`, and it'll get you up and running with everything you need (including database setup and management) on the server side.  For maximum configurability, you may choose not to use this class.  You may prefer to use the `puppetdb::server` class directly, or manage your puppetdb setup on your own.

You must declare the class to use it:

    class { 'puppetdb': }

**Parameters within `puppetdb`:**

####`listen_address`

The address that the web server should bind to for HTTP requests (defaults to `localhost`.'0.0.0.0' = all).

####`listen_port`

The port on which the puppetdb web server should accept HTTP requests (defaults to '8080').

####`open_listen_port`

If true, open the http_listen\_port on the firewall (defaults to false).

####`ssl_listen_address`

The address that the web server should bind to for HTTPS requests (defaults to `$::clientcert`). Set to '0.0.0.0' to listen on all addresses.

####`ssl_listen_port`

The port on which the puppetdb web server should accept HTTPS requests (defaults to '8081').

####`disable_ssl`

If true, the puppetdb web server will only serve HTTP and not HTTPS requests (defaults to false).

####`open_ssl_listen_port`

If true, open the ssl_listen\_port on the firewall (defaults to true).

####`database`

Which database backend to use; legal values are `postgres` (default) or `embedded`. The `embedded` db can be used for very small installations or for testing, but is not recommended for use in production environments. For more info, see the [puppetdb docs](http://docs.puppetlabs.com/puppetdb/).

####`database_port`

The port that the database server listens on (defaults to `5432`; ignored for `embedded` db).

####`database_username`

The name of the database user to connect as (defaults to `puppetdb`; ignored for `embedded` db).

####`database_password`

The password for the database user (defaults to `puppetdb`; ignored for `embedded` db).

####`database_name`

The name of the database instance to connect to (defaults to `puppetdb`; ignored for `embedded` db).

####`database_ssl`

If true, puppetdb will use SSL to connect to the postgres database (defaults to false; ignored for `embedded` db).
Setting up proper trust- and keystores has to be managed outside of the puppetdb module.

####`node_ttl`

The length of time a node can go without receiving any new data before it's automatically deactivated.  (defaults to '0', which disables auto-deactivation). This option is supported in PuppetDB >= 1.1.0.

####`node_purge_ttl`

The length of time a node can be deactivated before it's deleted from the database. (defaults to '0', which disables purging). This option is supported in PuppetDB >= 1.2.0.

####`report_ttl`

The length of time reports should be stored before being deleted. (defaults to '7d', which is a 7-day period). This option is supported in PuppetDB >= 1.1.0.

####`gc_interval`

This controls how often, in minutes, to compact the database. The compaction process reclaims space and deletes unnecessary rows. If not supplied, the default is every 60 minutes. This option is supported in PuppetDB >= 0.9.

####`log_slow_statements`

This sets the number of seconds before an SQL query is considered "slow." Slow SQL queries are logged as warnings, to assist in debugging and tuning. Note PuppetDB does not interrupt slow queries; it simply reports them after they complete.

The default value is 10 seconds. A value of 0 will disable logging of slow queries. This option is supported in PuppetDB >= 1.1.

####`conn_max_age`

The maximum time (in minutes), for a pooled connection to remain unused before it is closed off.

If not supplied, we default to 60 minutes. This option is supported in PuppetDB >= 1.1.

####`conn_keep_alive`

This sets the time (in minutes), for a connection to remain idle before sending a test query to the DB. This is useful to prevent a DB from timing out connections on its end.

If not supplied, we default to 45 minutes. This option is supported in PuppetDB >= 1.1.

####`conn_lifetime`

The maximum time (in minutes) a pooled connection should remain open. Any connections older than this setting will be closed off. Connections currently in use will not be affected until they are returned to the pool.

If not supplied, we won't terminate connections based on their age alone. This option is supported in PuppetDB >= 1.4.

####`puppetdb_package`

The puppetdb package name in the package manager.

####`puppetdb_version`

The version of the `puppetdb` package that should be installed.  You may specify an explicit version number, 'present', or 'latest' (defaults to 'present').

####`puppetdb_service`

The name of the puppetdb service.

####`puppetdb_service_status`

Sets whether the service should be running or stopped. When set to stopped the service doesn't start on boot either. Valid values are 'true', 'running', 'false', and 'stopped'.

####`confdir`

The puppetdb configuration directory (defaults to `/etc/puppetdb/conf.d`).

####`java_args`

Java VM options used for overriding default Java VM options specified in PuppetDB package (defaults to `{}`). See [PuppetDB Configuration](http://docs.puppetlabs.com/puppetdb/1.1/configure.html) to get more details about the current defaults.

Example: to set `-Xmx512m -Xms256m` options use `{ '-Xmx' => '512m', '-Xms' => '256m' }`

### puppetdb:server

The `puppetdb::server` class manages the puppetdb server independently of the underlying database that it depends on. It will manage the puppetdb package, service, config files, etc., but will still allow you to manage the database (e.g. postgresql) however you see fit.

    class { 'puppetdb::server':
      database_host => 'puppetdb-postgres',
    }

**Parameters within `puppetdb::server`:**

Uses the same parameters as `puppetdb`, with one addition:

####`database_host`

The hostname or IP address of the database server (defaults to `localhost`; ignored for `embedded` db).

### puppetdb::master::config

The `puppetdb::master::config` class directs your puppet master to use PuppetDB, which means that this class should be used on your puppet master node. It’ll verify that it can successfully communicate with your puppetdb server, and then configure your master to use PuppetDB.

Using this class involves allowing the module to manipulate your puppet configuration files; in particular: puppet.conf and routes.yaml. The puppet.conf changes are supplemental and should not affect any of your existing settings, but the routes.yaml file will be overwritten entirely. If you have an existing routes.yaml file, you will want to take care to use the manage_routes parameter of this class to prevent the module from managing that file, and you’ll need to manage it yourself.

    class { 'puppetdb::master::config':
      puppetdb_server => 'my.host.name',
      puppetdb_port   => 8081,
    }

**Parameters within `puppetdb::master::config`:**

####`puppetdb_server`

The dns name or ip of the puppetdb server (defaults to the certname of the current node).

####`puppetdb_port`

The port that the puppetdb server is running on (defaults to 8081).

####`puppetdb_soft_write_failure`

Boolean to fail in a soft-manner if PuppetDB is not accessable for command submission (defaults to false).

####`manage_routes`

If true, the module will overwrite the puppet master's routes file to configure it to use PuppetDB (defaults to true).

####`manage_storeconfigs`

If true, the module will manage the puppet master's storeconfig settings (defaults to true).

####`manage_report_processor`

If true, the module will manage the 'reports' field in the puppet.conf file to enable or disable the puppetdb report processor.  Defaults to 'false'.

####`manage_config`
If true, the module will store values from puppetdb_server and puppetdb_port parameters in the puppetdb configuration file.
If false, an existing puppetdb configuration file will be used to retrieve server and port values.

####`strict_validation`
If true, the module will fail if puppetdb is not reachable, otherwise it will preconfigure puppetdb without checking.

####`enable_reports`

Ignored unless `manage_report_processor` is `true`, in which case this setting will determine whether or not the puppetdb report processor is enabled (`true`) or disabled (`false`) in the puppet.conf file.

####`puppet_confdir`

Puppet's config directory (defaults to `/etc/puppet`).

####`puppet_conf`

Puppet's config file (defaults to `/etc/puppet/puppet.conf`).

####`puppetdb_version`

The version of the `puppetdb` package that should be installed. You may specify an explicit version number, 'present', or 'latest' (defaults to 'present').

####`terminus_package`

Name of the package to use that represents the PuppetDB terminus code.

####`puppet_service_name`

Name of the service that represents Puppet. You can change this to `apache2` or `httpd` depending on your operating system, if you plan on having Puppet run using Apache/Passenger for example.

####`puppetdb_startup_timeout`

The maximum amount of time that the module should wait for PuppetDB to start up. This is most important during the initial install of PuppetDB (defaults to 15 seconds).

####`restart_puppet`

If true, the module will restart the puppet master when PuppetDB configuration files are changed by the module.  The default is 'true'.  If set to 'false', you must restart the service manually in order to pick up changes to the config files (other than `puppet.conf`).

### puppetdb::database::postgresql
The `puppetdb::database::postgresql` class manages a postgresql server for use by PuppetDB. It can manage the postgresql packages and service, as well as creating and managing the puppetdb database and database user accounts.

    class { 'puppetdb::database::postgresql':
      listen_addresses => 'my.postgres.host.name',
    }

####`listen_addresses`

The `listen_address` is a comma-separated list of hostnames or IP addresses on which the postgres server should listen for incoming connections. This defaults to `localhost`. This parameter maps directly to postgresql's `listen_addresses` config option; use a `*` to allow connections on any accessible address.

####`manage_firewall`

If set to `true` this will enable open the local firewall for PostgreSQL protocol access. Defaults to `false`.

####`database_name`

Sets the name of the database. Defaults to `puppetdb`.

####`database_username`

Creates a user for access the database. Defaults to `puppetdb`.

####`database_password`

Sets the password for the database user above. Defaults to `puppetdb`.

Implementation
---------------

### Resource overview

In addition to the classes and variables mentioned above, PuppetDB includes:

**puppetdb::master::routes**

Configures the puppet master to use PuppetDB as the facts terminus. *WARNING*: the current implementation simply overwrites your routes.yaml file; if you have an existing routes.yaml file that you are using for other purposes, you should *not* use this.

    class { 'puppetdb::master::routes':
      puppet_confdir => '/etc/puppet'
    }

**puppetdb::master::storeconfigs**

Configures the puppet master to enable storeconfigs and to use PuppetDB as the storeconfigs backend.

    class { 'puppetdb::master::storeconfigs':
      puppet_conf => '/etc/puppet/puppet.conf'
    }

**puppetdb::server::validate_db**

Validates that a successful database connection can be established between the node on which this resource is run and the specified puppetdb database instance (host/port/user/password/database name).

    puppetdb::server::validate_db { 'validate my puppetdb database connection':
      database_host     => 'my.postgres.host',
      database_username => 'mydbuser',
      database_password => 'mydbpassword',
      database_name     => 'mydbname',
    }

### Custom Types

**puppetdb_conn_validator**

Verifies that a connection can be successfully established between a node and the puppetdb server. Its primary use is as a precondition to prevent configuration changes from being applied if the puppetdb server cannot be reached, but it could potentially be used for other purposes such as monitoring.

Limitations
------------

Currently, PuppetDB is compatible with:

    Puppet Version: 2.7+

Platforms:
* RHEL6
* Debian6
* Ubuntu 10.04
* Archlinux

Development
------------

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can’t access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

You can read the complete module contribution guide [on the Puppet Labs wiki.](http://projects.puppetlabs.com/projects/module-site/wiki/Module_contributing)
