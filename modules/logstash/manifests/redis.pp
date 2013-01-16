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
# Class to install redis.
#
class logstash::redis {
  # TODO(clarkb): Access to redis should be controlled at a network level
  # (with iptables) and with client authentication. Put this in place before
  # opening redis to external clients.

  package { 'redis-server':
    ensure => present,
  }

  file { '/etc/redis/redis.conf':
    ensure  => present,
    source  => 'puppet:///modules/logstash/redis.conf',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['redis-server'],
  }

  service { 'redis-server':
    ensure    => running,
    require   => Package['redis-server'],
    subscribe => File['/etc/redis/redis.conf'],
  }
}
