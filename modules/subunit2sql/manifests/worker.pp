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

# == Class: subunit_processor::worker
#
define subunit2sql::worker (
  $config_file,
  $subunit2sql_db_uri,
) {
  $suffix = "-${name}"

  include logstash::indexer
  if ! defined(File['/etc/logstash/subunit2sql.conf']) {
    file { '/etc/logstash/subunit2sql.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      content => template('subunit2sql/subunit2sql.conf.erb'),
      require => Class['logstash::indexer'],
    }
  }

  file { "/etc/logstash/jenkins-subunit-worker${suffix}.yaml":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => $config_file,
    require => Class['logstash::indexer'],
  }

  file { "/etc/init.d/jenkins-subunit-worker${suffix}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('subunit2sql/jenkins-subunit-worker.init.erb'),
    require => [
      File['/usr/local/bin/subunit-gearman-worker.py'],
      File["/etc/logstash/jenkins-subunit-worker${suffix}.yaml"],
    ],
  }

  service { "jenkins-subunit-worker${suffix}":
    enable     => true,
    hasrestart => true,
    subscribe  => File["/etc/logstash/jenkins-subunit-worker${suffix}.yaml"],
    require    => [
      Class['logstash::indexer'],
      File["/etc/init.d/jenkins-subunit-worker${suffix}"],
    ],
  }

  include logrotate
  logrotate::file { "subunit-worker${suffix}-debug.log":
    log     => "/var/log/logstash/subunit-worker${suffix}-debug.log",
    options => [
      'compress',
      'copytruncate',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service["jenkins-subunit-worker${suffix}"],
  }
}
