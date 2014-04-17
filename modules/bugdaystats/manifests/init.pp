# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Class: bugdaystats
#
class bugdaystats {
  if ! defined(Package['python-launchpadlib']) {
    package { 'python-launchpadlib':
      ensure => present,
    }
  }

  if ! defined(Package['python-jinja2']) {
    package { 'python-jinja2':
      ensure => present,
    }
  }

  if ! defined(Package['python-simplejson']) {
    package { 'python-simplejson':
      ensure => present,
    }
  }

  group { 'bugdaystats':
    ensure => present,
  }

  user { 'bugdaystats':
    ensure     => present,
    home       => '/var/lib/bugdaystats',
    shell      => '/bin/bash',
    gid        => 'bugdaystats',
    managehome => true,
    require    => Group['bugdaystats'],
  }

  file { '/var/lib/bugdaystats':
    ensure  => directory,
    owner   => 'bugdaystats',
    group   => 'bugdaystats',
    mode    => '0755',
    require => User['bugdaystats'],
  }
}
