# Class to configure puppetboard on a node.
# This will only work on the puppetdb server for now
class openstack_project::puppetboard(
  $basedir = $::puppetboard::params::basedir,
  $user    = $::puppetboard::params::user,
  $group   = $::puppetboard::params::group,
  $port    = '80',
) inherits ::puppetboard::params {

  include apache

  class { 'apache::mod::wsgi': }

  class { '::puppetboard':
    unresponsive => '.5',
    enable_query => 'False', # This being a python false
  }

  $docroot = "${basedir}/puppetboard"

  # Template Uses:
  # - $basedir
  #
  file { "${docroot}/wsgi.py":
    ensure  => present,
    content => template('puppetboard/wsgi.py.erb'),
    owner   => $user,
    group   => $group,
    require => User[$user],
  }

  # Template Uses:
  # - $docroot
  # - $user
  # - $group
  # - $port
  #
  apache::vhost { $::fqdn:
    port     => 80,
    docroot  => $docroot,
    priority => '50',
    template => 'openstack_project/puppetboard/puppetboard.vhost.erb',
  }

}
