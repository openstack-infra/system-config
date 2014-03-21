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
# Class to install kibana frontend to logstash.
#
class kibana (
  $discover_nodes     = ['localhost:9200'],
  $elasticsearch_url  = 'localhost:9200',
  $version            = '2',
  $port               = '80',
  $vhost_name         = $::fqdn,
  $serveradmin        = "webmaster@${::fqdn}",
) {

  group { 'kibana':
    ensure => present,
  }

  user { 'kibana':
    ensure     => present,
    comment    => 'Kibana User',
    home       => '/opt/kibana',
    gid        => 'kibana',
    shell      => '/bin/bash',
    membership => 'minimum',
    require    => Group['kibana'],
  }

  file { '/opt/kibana':
    ensure   => directory,
    owner    => 'kibana',
    group    => 'kibana',
    mode     => '0644',
    recurse  => true,
    require  => User['kibana'],
  }

  case $version {
    '2': {
      class { 'kibana::two':
        discover_nodes => $discover_nodes,
        port           => $port,
        vhost_name     => $vhost_name,
      }
    }

    '3': {
      class { 'kibana::three':
        elasticsearch_url => $elasticsearch_url,
        port              => $port,
        vhost_name        => $vhost_name,
      }
    }
  }
}
