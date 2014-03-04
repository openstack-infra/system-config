# Class to configure puppetboard on a node.
# This will only work on the puppetdb server for now
class openstack_project::puppetboard(
) {

  include apache

  class { 'apache::mod::wsgi': }

  class { '::puppetboard':
    enable_query => 'False', # This being a python false
  }

  class { 'puppetboard::apache::conf': }

  apache::vhost { $::fqdn:
    port     => 80,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'openstack_projects/puppetboard/puppetboard.vhost.erb',
  }

}
