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

# == Class: storyboard::load_superusers
#
# This module will load a batch of superusers into the storyboard database.
# The file should be formatted as yaml, with each entry similar to the
# following:
#
# - openid: https://login.launchpad.net/+id/some_openid
#   email: your_email@some_email_host.com
#
class storyboard::load_superusers (
  $source,
) {

  include storyboard::params
  include storyboard::application

  $superuser_file_path = '/var/lib/storyboard/superusers.yaml'

  file { $superuser_file_path:
    ensure  => present,
    owner   => $storyboard::params::user,
    group   => $storyboard::params::group,
    mode    => '0400',
    source  => $source,
    replace => true,
    require => [
      Class['storyboard::application'],
    ]
  }

  exec { 'load-superusers-yaml':
    command     => "storyboard-db-manage --config-file /etc/storyboard.conf load_superusers ${superuser_file_path}",
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => File[$superuser_file_path],
    require     => File[$superuser_file_path],
  }
}