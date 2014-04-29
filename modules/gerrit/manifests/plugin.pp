
#
# Defined resource type to install gerrit plugins.
#
# Borrowed from: https://github.com/jenkinsci/puppet-jenkins
#

define gerrit::plugin(
  $name = '',
  $version=0,
) {
  $base_plugin       = "${name}.jar"
  $plugin            = "${name}-${version}.jar"
  $plugin_cache_dir  = '/home/gerrit2/gerrit-plugins'
  $plugin_dir        = '/home/gerrit2/review_site/plugins'
  $plugin_parent_dir = '/home/gerrit2/review_site'
  $base_url          = "http://tarballs.openstack.org/ci/gerrit/plugins/${name}"

  include gerrit::user

  # This directory is used to download and cache gerrit plugin files.
  # That way the download and install steps are kept separate.
  if (!defined(File[$plugin_cache_dir])) {
    file { $plugin_cache_dir:
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        require => [
          File[$plugin_parent_dir],
          Class['gerrit::user'],
        ],
    }
  }

  # If we don't already have the specified plugin, download it.
  exec { "download:${plugin}":
    command => "/usr/bin/wget ${base_url}/${plugin} -O ${plugin_cache_dir}/${plugin}",
    creates => "${plugin_cache_dir}/${plugin}",
    user    => 'gerrit2',
    require => [
      File["${plugin_cache_dir}"],
      Class['gerrit::user'],
    ],
  }

  if (!defined(File[$plugin_dir])) {
    file { $plugin_dir:
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        require => [
          File[$plugin_parent_dir],
          Class['gerrit::user'],
        ],
    }
  }

  exec { "install-${base_plugin}":
    command  => "/bin/cp ${plugin_cache_dir}/${plugin} ${plugin_dir}/${base_plugin}",
    require  => [
      File[$plugin_dir],
      File["${plugin_cache_dir}/${plugin}"],
    ],
    user     => 'gerrit2',
    unless   => "test -f ${plugin_dir}/${base_plugin}",
  }

}
