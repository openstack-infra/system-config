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
class elasticsearch (
  $version = '0.20.5',
  $heap_size = '16g',
  $es_template_config = {}
) {
  # install java runtime
  package { 'java7-runtime-headless':
    ensure => present,
  }

  exec { 'get_elasticsearch_deb':
    command => "wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${version}.deb -O /tmp/elasticsearch-${version}.deb",
    path    => '/bin:/usr/bin',
    creates => "/tmp/elasticsearch-${version}.deb",
  }

  exec { 'gen_elasticsearch_deb_sha1':
    command => "sha1sum elasticsearch-${version}.deb > /tmp/elasticsearch-${version}.deb.sha1.gen",
    path    => '/bin:/usr/bin',
    cwd     => '/tmp',
    creates => "/tmp/elasticsearch-${version}.deb.sha1.gen",
    require => [
      Exec['get_elasticsearch_deb'],
    ]
  }

  exec { 'get_elasticsearch_deb_sha1':
    command => "wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${version}.deb.sha1.txt -O /tmp/elasticsearch-${version}.deb.sha1.txt",
    path    => '/bin:/usr/bin',
    creates => "/tmp/elasticsearch-${version}.deb.sha1.txt",
  }

  exec { 'check_elasticsearch_sha1':
    command => "diff /tmp/elasticsearch-${version}.deb.sha1.txt /tmp/elasticsearch-${version}.deb.sha1.gen",
    path    => '/bin:/usr/bin',
    require => [
      Exec['gen_elasticsearch_deb_sha1'],
      Exec['get_elasticsearch_deb_sha1'],
    ]
  }

  # install elastic search
  package { 'elasticsearch':
    ensure    => latest,
    source    => "/tmp/elasticsearch-${version}.deb",
    provider  => 'dpkg',
    subscribe => Exec['get_elasticsearch_deb'],
    require   => [
      Package['java7-runtime-headless'],
      Exec['check_elasticsearch_sha1'],
      File['/etc/elasticsearch/elasticsearch.yml'],
      File['/etc/elasticsearch/default-mapping.json'],
      File['/etc/default/elasticsearch'],
    ]
  }

  file { '/etc/elasticsearch':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/elasticsearch/elasticsearch.yml':
    ensure  => present,
    content => template('elasticsearch/elasticsearch.yml.erb'),
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/elasticsearch'],
  }

  file { '/etc/elasticsearch/templates':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/elasticsearch'],
  }

  file { '/etc/elasticsearch/default-mapping.json':
    ensure  => present,
    source  => 'puppet:///modules/elasticsearch/elasticsearch.mapping.json',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/elasticsearch'],
  }

  file { '/etc/default/elasticsearch':
    ensure  => present,
    content => template('elasticsearch/elasticsearch.default.erb'),
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  service { 'elasticsearch':
    ensure    => running,
    require   => Package['elasticsearch'],
  }
}
