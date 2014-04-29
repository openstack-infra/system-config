
#
# Defined resource type to install gerrit plugins.
#
# Borrowed from: https://github.com/jenkinsci/puppet-jenkins
#

define gerrit::plugin(
  $version=0,
) {
  $plugin            = "${name}-${version}.jar"
  $plugin_dir        = '/home/gerrit2/review_site/plugins'
  $plugin_parent_dir = '/home/gerrit2/review_site'
  $base_url          = "http://tarballs.openstack.org/ci/gerrit/plugins/${name}"

  if (!defined(File[$plugin_dir])) {
    file { $plugin_dir:
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        require => [File[$plugin_parent_dir],
                   Class['gerrit::user']],
    }
  }

  include gerrit::user

  exec { "download-${name}" :
    command  => "wget --no-check-certificate ${base_url}/${plugin}",
    cwd      => $plugin_dir,
    require  => [File[$plugin_dir],
                Class['gerrit::user']],
    path     => ['/usr/bin', '/usr/sbin',],
    user     => 'gerrit2',
    unless   => "test -f ${plugin_dir}/${plugin}",
  }
}
