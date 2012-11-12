# Copyright 2012 Hewlett-Packard Development Company, L.P.
# Copyright 2012 Paul Belanger
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

class github(
  $username,
  $oauth_token,
  $projects = []
) {
  include pip

  package { 'PyGithub':
    ensure   => latest,  # okay to use latest for pip
    provider => pip,
    require  => Class['pip'],
  }

  # A lot of things need yaml, be conservative requiring this package to avoid
  # conflicts with other modules.
  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  group { 'github':
    ensure => present,
  }

  user { 'github':
    ensure  => present,
    comment => 'Github API User',
    shell   => '/bin/bash',
    gid     => 'github',
    require => Group['github'],
  }

  file { '/etc/github':
    ensure => directory,
    group  => 'root',
    mode   => '0755',
    owner  => 'root',
  }

  file { '/etc/github/github.config':
    ensure => absent,
  }

  file { '/etc/github/github.secure.config':
    ensure  => present,
    content => template('github/github.secure.config.erb'),
    group   => 'github',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => [
      Group['github'],
      File['/etc/github']
    ],
  }

  file { '/usr/local/github':
    ensure => directory,
    group  => 'root',
    mode   => '0755',
    owner  => 'root',
  }

  file { '/usr/local/github/scripts':
    ensure  => directory,
    group   => 'root',
    mode    => '0755',
    owner   => 'root',
    recurse => true,
    require => File['/usr/local/github'],
    source  => 'puppet:///modules/github/scripts',
  }

  cron { 'githubclosepull':
    command => 'sleep $((RANDOM\%60+90)) && python /usr/local/github/scripts/close_pull_requests.py',
    minute  => '*/5',
    require => [
      File['/usr/local/github/scripts'],
      Package['python-yaml'],
      Package['PyGithub'],
    ],
    user    => github,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
