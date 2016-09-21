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
# Logstash indexer worker glue class.
#
class openstack_project::logstash_worker (
  $discover_node = 'elasticsearch01.openstack.org',
  $filter_rev    = 'master',
  $filter_source = 'https://git.openstack.org/openstack-infra/logstash-filters',
  $enable_mqtt = false,
  $mqtt_hostname = 'firehose.openstack.org',
  $mqtt_port = 8883,
  $mqtt_topic = "logstash/${::hostname}",
  $mqtt_username = 'infra',
  $mqtt_password = undef,
  $mqtt_ca_cert_contents = undef,
) {
  file { '/etc/default/logstash-indexer':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/openstack_project/logstash/logstash-indexer.default',
  }

  vcsrepo { '/opt/logstash-filters':
    ensure   => latest,
    provider => git,
    revision => $filter_rev,
    source   => $filter_source,
  }

  include ::logstash

  logstash::filter { 'openstack-logstash-filters':
    level   => '50',
    target  => '/opt/logstash-filters/filters/openstack-filters.conf',
    require => [
      Class['::logstash'],
      Vcsrepo['/opt/logstash-filters'],
    ],
    notify  => Service['logstash'],
  }

  class { '::logstash::indexer':
    input_template         => 'openstack_project/logstash/input.conf.erb',
    output_template        => 'openstack_project/logstash/output.conf.erb',
    enable_mqtt            => $enable_mqtt,
    mqtt_ca_cert_contents  => $mqtt_ca_cert_contents,
    require                => Logstash::Filter['openstack-logstash-filters'],
  }

  include ::log_processor
  log_processor::worker { 'A':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
  log_processor::worker { 'B':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
  log_processor::worker { 'C':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
  log_processor::worker { 'D':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-worker.yaml',
  }
}
