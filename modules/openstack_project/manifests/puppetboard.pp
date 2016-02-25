# Class to configure puppetboard on a node.
# This will only work on the puppetdb server for now
class openstack_project::puppetboard(
  $basedir = $::puppetboard::params::basedir,
  $user    = $::puppetboard::params::user,
  $group   = $::puppetboard::params::group,
  $port    = '80',
) inherits ::puppetboard::params {

  include ::httpd

  class { '::httpd::mod::wsgi': }

  class { '::puppetboard':
    unresponsive => '1.5',
    enable_query => 'False', # This being a python false
    git_source   => 'https://github.com/voxpupuli/puppetboard',
    revision     => '3042e22a1b4dfc0e3b7f3850c77da5a9398a8a52',
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
  ::httpd::vhost { $::fqdn:
    port     => 80,
    docroot  => $docroot,
    priority => '50',
    template => 'openstack_project/puppetboard/puppetboard.vhost.erb',
    require  => [
      User[$user],
      Group[$group],
    ],
  }

}
