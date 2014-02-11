# Manages the routes configuration file on the master. See README.md for more
# details.
class puppetdb::master::routes(
  $puppet_confdir = $puppetdb::params::puppet_confdir,
) inherits puppetdb::params {

  # TODO: this will overwrite any existing routes.yaml;
  #  to handle this properly we should just be ensuring
  #  that the proper settings exist, but to do that we'd need
  #  to parse the yaml file and rewrite it, dealing with indentation issues etc.
  #  I don't think there is currently a puppet module or an augeas lens for this.
  file { "${puppet_confdir}/routes.yaml":
    ensure => file,
    source => 'puppet:///modules/puppetdb/routes.yaml',
  }
}
