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

# == Class: storyboard::workers
#
# This module installs the storyboard deferred processing workers.
#
class storyboard::workers (
  $worker_count = 5
) {

  require storyboard::application

  if defined(Class['::storyboard::rabbit']) {
    $so_rabbit = 'rabbitmq-server '
  } else {
    $so_rabbit = ''
  }

  if defined(Class['::storyboard::mysql']) {
    $so_mysql = 'mysql '
  } else {
    $so_mysql = ''
  }

  file { '/etc/init/storyboard-workers.conf':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('storyboard/storyboard-workers.conf.erb'),
    notify  => Service['storyboard-workers'],
  }

  file { '/etc/init/storyboard-worker.conf':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('storyboard/storyboard-worker.conf.erb'),
    notify  => Service['storyboard-workers'],
  }

  service { 'storyboard-workers':
    ensure     => running,
    hasrestart => true,
    subscribe  => [
      Class['::storyboard::application']
    ],
    require    => [
      File['/etc/init/storyboard-workers.conf'],
      File['/etc/init/storyboard-worker.conf']
    ]
  }
}