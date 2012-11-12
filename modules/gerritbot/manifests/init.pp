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

class gerritbot(
  $nick,
  $password,
  $server,
  $user,
  $vhost_name
) {
  include pip

  package { 'gerritbot':
    ensure   => present,  # Pip upgrade is not working
    provider => pip,
    require  => Class['pip']
  }

  file { '/etc/init.d/gerritbot':
    ensure  => present,
    group   => 'root',
    mode    => '0555',
    owner   => 'root',
    require => Package['gerritbot'],
    source  => 'puppet:///modules/gerritbot/gerritbot.init',
  }

  service { 'gerritbot':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/gerritbot'],
    subscribe  => [
      Package['gerritbot'],
      File['/etc/gerritbot/gerritbot.config'],
      File['/etc/gerritbot/channel_config.yaml']
    ],
  }

  file { '/etc/gerritbot':
    ensure => directory,
  }

  file { '/var/log/gerritbot':
    ensure => directory,
    group  => 'gerrit2',
    mode   => '0775',
    owner  => 'root',
  }

  file { '/etc/gerritbot/channel_config.yaml':
    ensure  => present,
    group   => 'gerrit2',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['gerrit2'],
    source  => 'puppet:///modules/gerritbot/gerritbot_channel_config.yaml',
  }

  file { '/etc/gerritbot/logging.config':
    ensure  => present,
    group   => 'gerrit2',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['gerrit2'],
    source  => 'puppet:///modules/gerritbot/logging.config',
  }

  file { '/etc/gerritbot/gerritbot.config':
    ensure  => present,
    content => template('gerritbot/gerritbot.config.erb'),
    group   => 'gerrit2',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['gerrit2'],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
