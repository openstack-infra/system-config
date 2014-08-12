#  Copyright (C) 2014 R. Tyler Croy <tyler@monkeypox.org>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
# Defined resource type to install jenkins plugins.
#
# Borrowed from: https://github.com/jenkinsci/puppet-jenkins
#

define jenkins::plugin(
  $version=0,
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
