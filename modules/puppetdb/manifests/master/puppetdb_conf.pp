# Managed the puppetdb.conf file on the puppeet master. See README.md for more
# details.
class puppetdb::master::puppetdb_conf (
  $server             = 'localhost',
  $port               = '8081',
  $soft_write_failure = $puppetdb::disable_ssl ? { true => true, default => false, },
  $puppet_confdir     = $puppetdb::params::puppet_confdir,
) inherits puppetdb::params {

  Ini_setting {
    ensure  => present,
    section => 'main',
    path    => "${puppet_confdir}/puppetdb.conf",
  }

  ini_setting { 'puppetdbserver':
    setting => 'server',
    value   => $server,
  }

  ini_setting { 'puppetdbport':
    setting => 'port',
    value   => $port,
  }

  ini_setting { 'soft_write_failure':
    setting => 'soft_write_failure',
    value   => $soft_write_failure,
  }
}
