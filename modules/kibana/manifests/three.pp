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
class kibana::three (
  $port               = '80',
  $es_port            = '9200',
  $vhost_name         = $::fqdn,
  $elasticsearch_url  = 'localhost:9200',
  $serveradmin        = "webmaster@${::fqdn}",
) {

  include kibana::common

  vcsrepo { '/opt/kibana/three':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/elasticsearch/kibana.git',
    revision => 'v3.0.0milestone5',
    require  => File['/opt/kibana'],
  }

  apache::vhost { $vhost_name:
    port     => $port,
    priority => '50',
    template => 'kibana/three.vhost.erb'
  }

  apache::vhost { $vhost_name:
    port     => $es_port,
    priority => '50',
    template => 'kibana/elasticproxy.vhost.erb'
  }

}
