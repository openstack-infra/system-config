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
# Class to install common logstash items.
#
class logstash {
  group { 'logstash':
    ensure => present,
  }

  user { 'logstash':
    ensure     => present,
    comment    => 'Logstash User',
    home       => '/opt/logstash',
    gid        => 'logstash',
    shell      => '/bin/bash',
    membership => 'minimum',
    require    => Group['logstash'],
  }

  file { '/opt/logstash':
    ensure   => directory,
    owner    => 'logstash',
    group    => 'logstash',
    mode     => '0644',
    require  => User['logstash'],
  }

  exec { 'get_logstash_jar':
    command => 'wget https://download.elasticsearch.org/logstash/logstash/logstash-1.3.3-flatjar.jar -O /opt/logstash/logstash-1.3.3-flatjar.jar',
    path    => '/bin:/usr/bin',
    creates => '/opt/logstash/logstash-1.3.3-flatjar.jar',
    require => File['/opt/logstash'],
  }

  file { '/opt/logstash/logstash-1.3.3-flatjar.jar':
    ensure  => present,
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0644',
    require => [
      User['logstash'],
      Exec['get_logstash_jar'],
    ]
  }

  file { '/opt/logstash/logstash.jar':
    ensure  => link,
    target  => '/opt/logstash/logstash-1.3.3-flatjar.jar',
    require => File['/opt/logstash/logstash-1.3.3-flatjar.jar'],
  }

  file { '/var/log/logstash':
    ensure => directory,
    owner  => 'logstash',
    group  => 'logstash',
    mode   => '0644',
  }

  file { '/etc/logstash':
    ensure => directory,
    owner  => 'logstash',
    group  => 'logstash',
    mode   => '0644',
  }

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }
}
