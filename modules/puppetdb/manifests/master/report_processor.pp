# Manages the installation of the report processor on the master. See README.md
# for more details.
class puppetdb::master::report_processor(
  $puppet_conf = $puppetdb::params::puppet_conf,
  $enable      = false
) inherits puppetdb::params {
  ini_subsetting { 'puppet.conf/reports/puppetdb':
    ensure               => $enable ? {
      true    => present,
      default => absent
    },
    path                 => $puppet_conf,
    section              => 'master',
    setting              => 'reports',
    subsetting           => 'puppetdb',
    subsetting_separator => ','
  }
}
