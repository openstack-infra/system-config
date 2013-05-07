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
# Class to install elasticsearch.
#
class logstash::elasticsearch {
  # install java runtime
  package { 'java7-runtime-headless':
    ensure => present,
  }

  exec { 'get_elasticsearch_deb':
    command => 'wget http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.2.deb -O /tmp/elasticsearch-0.20.2.deb',
    path    => '/bin:/usr/bin',
    creates => '/tmp/elasticsearch-0.20.2.deb',
  }

  # install elastic search
  package { 'elasticsearch':
    ensure   => present,
    source   => '/tmp/elasticsearch-0.20.2.deb',
    provider => 'dpkg',
    require  => [
      Package['java7-runtime-headless'],
      Exec['get_elasticsearch_deb'],
    ]
  }

  file { '/etc/elasticsearch/elasticsearch.yml':
    ensure  => present,
    source  => 'puppet:///modules/logstash/elasticsearch.yml',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['elasticsearch'],
  }

  file { '/etc/elasticsearch/default-mapping.json':
    ensure  => present,
    source  => 'puppet:///modules/logstash/elasticsearch.mapping.json',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['elasticsearch'],
  }

  file { '/etc/default/elasticsearch':
    ensure  => present,
    source  => 'puppet:///modules/logstash/elasticsearch.default',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['elasticsearch'],
  }

  service { 'elasticsearch':
    ensure    => running,
    require   => Package['elasticsearch'],
    subscribe => [
      File['/etc/elasticsearch/elasticsearch.yml'],
      File['/etc/elasticsearch/default-mapping.json'],
      File['/etc/default/elasticsearch'],
    ],
  }
}
