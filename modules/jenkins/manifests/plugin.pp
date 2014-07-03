#
# Defined resource type to install jenkins plugins.
#
# Borrowed from: https://github.com/jenkinsci/puppet-jenkins
#

define jenkins::plugin(
  $version=0,
  $doupdate=false,
) {
  $plugin            = "${name}.hpi"
  $plugin_dir        = '/var/lib/jenkins/plugins'
  $plugin_parent_dir = '/var/lib/jenkins'

  if ($version != 0) {
    $base_url = "http://updates.jenkins-ci.org/download/plugins/${name}/${version}"
  }
  else {
    $base_url   = 'http://updates.jenkins-ci.org/latest'
  }

  if (!defined(File[$plugin_dir])) {
    file {
      [
        $plugin_parent_dir,
        $plugin_dir,
      ]:
        ensure  => directory,
        owner   => 'jenkins',
        group   => 'jenkins',
        require => [Group['jenkins'], User['jenkins']],
    }
  }

  if (!defined(Group['jenkins'])) {
    group { 'jenkins' :
      ensure => present,
    }
  }

  if (!defined(User['jenkins'])) {
    user { 'jenkins' :
      ensure => present,
    }
  }
# if doupdate is true, check if the plugin is already installed , if so remove it for update
# stage the plugin update so that later jenkins restarts pickup the new plugin.
  if $::kernel == 'Linux' and $version != 0 and $doupdate == true
  {
    $doupdate_test = "find . -type d|egrep '.*${name}\\/META-INF\$' | xargs -i grep -H Plugin-Version {}/MANIFEST.MF|sed 's/^\\.\\///g' |sed 's/MANIFEST.MF:Plugin-Version://g'|sed 's/META-INF\\/ //g'|awk -F '/' '{print \$1\"=\"\$2}'"
    exec { "remove-for-update-${name}":
      command => "rm -rf '${plugin_dir}/${name}'",
      cwd     => $plugin_dir,
      require => File[$plugin_dir],
      path    => ['/bin', '/usr/bin', '/usr/sbin'],
      user    => 'jenkins',
      unless  => [  "test ! -d '${plugin_dir}/${name}'",
      "test ! \$(${doupdate_test}) = \"${name}=${version}\"",
      ],
      before  => Exec["download-${name}"],
    }
    exec { "remove-plugin-file ${name}":
      command   => "rm -f '${plugin_dir}/${name}.?pi'",
      cwd       => $plugin_dir,
      require   => File[$plugin_dir],
      path      => ['/bin', '/usr/bin', '/usr/sbin'],
      user      => 'jenkins',
      unless    => "test ! -f '${plugin_dir}/${name}.?pi'",
      subscribe => Exec["remove-for-update-${name}"],
    }
  }

  exec { "download-${name}" :
    command  => "wget --no-check-certificate ${base_url}/${plugin}",
    cwd      => $plugin_dir,
    require  => File[$plugin_dir],
    path     => ['/usr/bin', '/usr/sbin',],
    user     => 'jenkins',
    unless   => "test -f ${plugin_dir}/${name}.?pi",
#    OpenStack modification: don't auto-restart jenkins so we can control
#    outage timing better.
#    notify   => Service['jenkins'],
  }
}
