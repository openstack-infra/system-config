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
#
# A machine ready to run devstack
class devstack_host {
  package { 'linux-headers-virtual':
    ensure => present,
  }

  package { 'mysql-server':
    ensure => present,
  }

  package { 'rabbitmq-server':
    ensure => present,
    require => File['/etc/rabbitmq/rabbitmq-env.conf'],
  }

  file { '/etc/rabbitmq':
    ensure => directory,
  }

  file { '/etc/rabbitmq/rabbitmq-env.conf':
    ensure  => present,
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    require => File['/etc/rabbitmq'],
    source  => 'puppet:///modules/devstack_host/rabbitmq-env.conf',
  }

  # TODO: We should be using existing mysql functions do this.
  exec { 'Set MySQL server root password':
    command     => 'mysqladmin -uroot password secret',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Package['mysql-server'],
    unless      => 'mysqladmin -uroot -psecret status',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
