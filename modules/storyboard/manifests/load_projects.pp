# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: storyboard::load_projects
#
# This module will preload a batch of projects into the storyboard database.
# The file should be formatted as yaml, with each entry similar to the
# following:
#
# - project: openstack/storyboard
#   description: The StoryBoard API
#   use-storyboard: true
# - project: openstack/storyboard-webclient
#   description: The StoryBoard HTTP client
#   use-storyboard: true
#
class storyboard::load_projects (
  $source
) {
  
  include storyboard::params
  include storyboard::application
  
  $project_file_path = '/var/lib/storyboard/projects.yaml'
  
  file { "${project_file_path}":
    ensure  => present,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    mode    => '0400',
    source  => $source,
    replace => true,
    require => [
      Class['storyboard::application']
    ]
  }
  
  exec { 'load-projects-yaml':
    command     => "storyboard-db-manage --config-file /etc/storyboard.conf load_projects ${project_file_path}",
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => File["${project_file_path}"],
    require     => File["${project_file_path}"]
  }
}