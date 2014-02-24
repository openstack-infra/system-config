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
# Class to install a simple watchdog for the logstash-indexer service.
# es_api_node is the address to access the elasticsearch api at (should
# be a 'host:port' string).

class logstash::watchdog (
  $es_api_node = 'localhost'
) {
  package { 'jq':
    ensure => present,
  }

  file { '/usr/local/bin/logstash-watchdog':
    ensure  => present,
    source  => 'puppet:///modules/logstash/logstash-watchdog.sh',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
  }

  cron { 'logstash-watchdog':
    minute      => '*/10',
    environment => 'PATH=/bin:/usr/bin:/usr/local/bin',
    command     => "sleep $((RANDOM\%60)) && /usr/local/bin/logstash-watchdog ${es_api_node}",
    require     => Service['logstash-indexer']
  }
}
