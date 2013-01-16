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
# Class to install logstash indexer.
# conf_template accepts path to indexer config template.
#
class logstash::indexer (
  $conf_template = 'logstash/indexer.conf.erb'
) {
  include logstash

  file { '/etc/init/logstash-indexer.conf':
    ensure  => present,
    source  => 'puppet:///modules/logstash/logstash-indexer.conf',
    replace => true,
    owner   => 'root',
  }

  file { '/etc/logstash/indexer.conf':
    ensure  => present,
    content => template($conf_template),
    replace => true,
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0644',
    require => Class['logstash'],
  }

  service { 'logstash-indexer':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/logstash/indexer.conf'],
    require   => [
      Class['logstash'],
      File['/etc/init/logstash-indexer.conf'],
    ]
  }
}
