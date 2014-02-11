# This class configures the puppet master to enable storeconfigs and to use
# puppetdb as the storeconfigs backend. See README.md for more details.
class puppetdb::master::storeconfigs(
  $puppet_conf = $puppetdb::params::puppet_conf
) inherits puppetdb::params {

  Ini_setting{
    section => 'master',
    path    => $puppet_conf,
    ensure  => present,
  }

  ini_setting { 'puppet.conf/master/storeconfigs':
    setting => 'storeconfigs',
    value   => true,
  }

  ini_setting { 'puppet.conf/master/storeconfigs_backend':
    setting => 'storeconfigs_backend',
    value   => 'puppetdb',
  }
}
