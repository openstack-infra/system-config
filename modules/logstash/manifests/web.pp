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
# Class to run logstash web front end.
#
class logstash::web (
  $vhost_name = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $frontend = 'internal',
  $elasticsearch_host = 'localhost',
) {
  include apache
  a2mod { 'rewrite':
    ensure => present,
  }
  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
  }

  include logstash

  case $frontend {
    'internal': {
      file { '/etc/init/logstash-web.conf':
        ensure  => present,
        source  => 'puppet:///modules/logstash/logstash-web.conf',
        replace => true,
        owner   => 'root',
      }

      service { 'logstash-web':
        ensure    => running,
        enable    => true,
        require   => [
          Class['logstash'],
          File['/etc/init/logstash-web.conf'],
        ],
      }

      $vhost = 'logstash/logstash.vhost.erb'
    }

    'kibana': {
      class { 'kibana':
        elasticsearch_host => $elasticsearch_host,
      }
      $vhost = 'logstash/kibana.vhost.erb'
    }

    default: {
      fail("Unknown frontend to logstash: ${frontend}.")
    }
  }

  apache::vhost { $vhost_name:
    port     => 80,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => $vhost,
  }
}
