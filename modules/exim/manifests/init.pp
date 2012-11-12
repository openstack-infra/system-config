# Copyright 2011 Hewlett-Packard Development Company, L.P.
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

class exim(
  $mailman_domains = [],
  $sysadmin = []
) {
  package { 'exim4-base':
    ensure => present,
  }

  package { 'exim4-config':
    ensure => present,
  }

  package { 'exim4-daemon-light':
    ensure  => present,
    require => [
      Package[exim4-base],
      Package[exim4-config]
    ],
  }

  service { 'exim4':
    ensure      => running,
    hasrestart  => true,
    subscribe   => File['/etc/exim4/exim4.conf'],
  }

  file { '/etc/exim4/exim4.conf':
    ensure  => present,
    content => template('exim/exim4.conf.erb'),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
  }

  file { '/etc/aliases':
    ensure  => present,
    content => template('exim/aliases.erb'),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
