# Copyright 2013 Thierry Carrez
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
# Class: releasestatus
#
class releasestatus (
  $releasestatus_prvkey_contents = '',
  $releasestatus_pubkey_contents = '',
  $releasestatus_gerrit_ssh_key = '',
) {
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

  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  group { 'releasestatus':
    ensure => present,
  }

  user { 'releasestatus':
    ensure     => present,
    home       => '/var/lib/releasestatus',
    shell      => '/bin/bash',
    gid        => 'releasestatus',
    managehome => true,
    require    => Group['releasestatus'],
  }

  file { '/var/lib/releasestatus':
    ensure  => directory,
    owner   => 'releasestatus',
    group   => 'releasestatus',
    mode    => '0755',
    require => User['releasestatus'],
  }

  file { '/var/lib/releasestatus/.ssh/':
    ensure  => directory,
    owner   => 'releasestatus',
    group   => 'releasestatus',
    mode    => '0700',
    require => File['/var/lib/releasestatus'],
  }

  if $releasestatus_prvkey_contents != '' {
    file { '/var/lib/releasestatus/.ssh/id_rsa':
      owner   => 'releasestatus',
      group   => 'releasestatus',
      mode    => '0600',
      content => $releasestatus_prvkey_contents,
      replace => true,
      require => File['/var/lib/releasestatus/.ssh/']
    }
  }

  if $releasestatus_pubkey_contents != '' {
    file { '/var/lib/releasestatus/.ssh/id_rsa.pub':
      owner   => 'releasestatus',
      group   => 'releasestatus',
      mode    => '0600',
      content => $releasestatus_pubkey_contents,
      replace => true,
      require => File['/var/lib/releasestatus/.ssh/']
    }
  }

  if $releasestatus_gerrit_ssh_key != '' {
    file { '/var/lib/releasestatus/.ssh/known_hosts':
      owner   => 'releasestatus',
      group   => 'releasestatus',
      mode    => '0600',
      content => "review.openstack.org ${releasestatus_gerrit_ssh_key}",
      replace => true,
      require => File['/var/lib/releasestatus/.ssh/']
    }
  }

  file { '/var/lib/releasestatus/.ssh/config':
    owner   => 'releasestatus',
    group   => 'releasestatus',
    mode    => '0600',
    source  => 'puppet:///modules/releasestatus/ssh_config',
    replace => true,
    require => File['/var/lib/releasestatus/.ssh/']
  }

  vcsrepo { '/var/lib/releasestatus/releasestatus':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/openstack-infra/releasestatus.git',
    revision => 'master',
    require  => File['/var/lib/releasestatus'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
