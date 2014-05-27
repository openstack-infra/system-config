# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2014 OpenStack Foundation
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

# == Class: zuul::server
#
class zuul::server (
) {
  service { 'zuul':
    name       => 'zuul',
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/zuul'],
  }

  exec { 'zuul-reload':
    command     => '/etc/init.d/zuul reload',
    require     => File['/etc/init.d/zuul'],
    refreshonly => true,
  }

  include logrotate
  logrotate::file { 'zuul.log':
    log     => '/var/log/zuul/zuul.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul'],
  }
  logrotate::file { 'zuul-debug.log':
    log     => '/var/log/zuul/debug.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul'],
  }
  logrotate::file { 'gearman-server.log':
    log     => '/var/log/zuul/gearman-server.log',
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service['zuul'],
  }
}
