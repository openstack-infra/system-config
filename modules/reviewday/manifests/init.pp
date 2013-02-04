# Copyright 2013 Hewlett-Packard Development Company, L.P.
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
# Define: reviewday
#
define reviewday::init(
  $gerrit_url = '',
  $gerrit_port = '',
  $gerrit_user = '',
  $reviewday_rsa_key_contents = '',
  $reviewday_rsa_pubkey_contents = '',
  $reviewday_gerrit_ssh_key = ''
) {
    if ! defined(Package['python-launchpadlib']) {
      package { 'python-launchpadlib':
        ensure => present,
      }
    }
    package { 'python-cheetah':
      ensure => present,
    }

  group { 'reviewday':
    ensure => present,
  }

  user { 'reviewday':
    ensure     => present,
    home       => "/var/lib/${name}",
    shell      => '/bin/bash',
    gid        => 'reviewday',
    managehome => true,
    require    => Group['reviewday'],
  }

  file { "/var/lib/${name}/.ssh/":
    ensure  => directory,
    owner   => 'reviewday',
    group   => 'reviewday',
    mode    => '0700',
    require => User['reviewday'],
  }

  if $reviewday_rsa_key_contents != '' {
    file { "/var/lib/${name}/.ssh/id_rsa":
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_rsa_key_contents,
      replace => true,
      require => File["/var/lib/${name}/.ssh/"]
    }
  }

  if $reviewday_rsa_pubkey_contents != '' {
    file { "/var/lib/${name}/.ssh/id_rsa.pub":
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_rsa_pubkey_contents,
      replace => true,
      require => File["/var/lib/${name}/.ssh/"]
    }
  }

  if $reviewday_gerrit_ssh_key != '' {
    file { "/var/lib/${name}/.ssh/known_hosts":
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_gerrit_ssh_key,
      replace => true,
      require => File["/var/lib/${name}/.ssh/"]
    }
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
