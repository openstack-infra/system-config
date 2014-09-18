# Copyright 2014 Hewlett-Packard Development Company, L.P.
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

# == Class: mysql_proxy
#
class mysql_proxy {

    package { 'mysql-proxy':
      ensure => present,
    }

    file { '/etc/mysql-proxy':
      ensure   => directory,
      owner    => 'root',
      group    => 'root',
      mode     => '0644',
      require  => Package['mysql-proxy'],

    }

    file { '/etc/default/mysql-proxy':
      owner    => 'root',
      group    => 'root',
      mode     => '0644',
      source   => 'puppet:///modules/mysql_proxy/mysql-proxy',
      require  => Package['mysql-proxy'],
    }

}
