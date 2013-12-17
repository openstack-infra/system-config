# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2013 OpenStack Foundation
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

# == Class: log_processor::worker
#
define log_processor::worker (
  $config_file,
) {
  $suffix = "-${name}"

  file { "/etc/logstash/jenkins-log-worker${suffix}.yaml":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => $config_file,
    require => Class['logstash::indexer'],
  }

  file { "/etc/init.d/jenkins-log-worker${suffix}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('log_processor/jenkins-log-worker.init.erb'),
    require => [
      File['/usr/local/bin/log-gearman-worker.py'],
      File["/etc/logstash/jenkins-log-worker${suffix}.yaml"],
    ],
  }

  service { "jenkins-log-worker${suffix}":
    enable     => true,
    hasrestart => true,
    subscribe  => File["/etc/logstash/jenkins-log-worker${suffix}.yaml"],
    require    => [
      Class['logstash::indexer'],
      File["/etc/init.d/jenkins-log-worker${suffix}"],
    ],
  }

  include logrotate
  logrotate::file { "log-worker${suffix}-debug.log":
    log     => "/var/log/logstash/log-worker${suffix}-debug.log",
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service["jenkins-log-worker${suffix}"],
  }
}
