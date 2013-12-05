# Copyright 2013 Hewlett-Packard Development Company, L.P.
# Copyright 2013 Samsung Electronics
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
# Class to install and configure an instance of the elastic-recheck
# service.
#
class elastic_recheck::bot (
  $gerrit_ssh_private_key,
  $gerrit_ssh_private_key_contents
) {
  file { '/home/recheck':
    ensure  => directory,
    mode    => '0700',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/home/recheck/.ssh':
    ensure  => directory,
    mode    => '0700',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { $gerrit_ssh_private_key:
    ensure  => present,
    mode    => '0600',
    owner   => 'recheck',
    group   => 'recheck',
    content => $gerrit_ssh_private_key_contents,
    require => User['recheck'],
  }

  file { '/etc/init.d/elastic-recheck':
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/elastic_recheck/elastic-recheck.init',
  }

  service { 'elastic-recheck':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/elastic-recheck/elastic-recheck.conf'],
    require   => [
      File['/etc/init.d/elastic-recheck'],
      File['/etc/elastic-recheck/elastic-recheck.conf'],
      File['/etc/elastic-recheck/queries.yaml'],
      Exec['install_elastic-recheck'],
    ],
  }
}
