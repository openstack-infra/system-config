# Class to configure puppetboard on a node.
# This will only work on the puppetdb server for now
class openstack_project::puppetboard(
) {

  include apache

  class { 'apache::mod::wsgi': }

  class { 'puppetboard': }

  class { 'puppetboard::apache::conf': }

}
