# Class to configure puppetboard on a node.
# This will only work on the puppetdb server for now
class openstack_project::puppetboard(
) {

  include apache

  class { 'apache::mod::wsgi': }

  class { 'puppetboard':
    $enable_query = 'False', # This being a python false
  }

  class { 'puppetboard::apache::conf': }

}
