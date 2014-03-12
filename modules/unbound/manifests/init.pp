# Copyright (C) 2014 OpenStack Foundation
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

# == Class: unbound

# This installs unbound in its default configuration as a caching
# recursive resolver and configures /etc/unbound/conf.d if needed.

class unbound (
) {
  package { 'unbound':
    ensure => present,
  }

  # RedHat has a conf.d/* include in its config already; make Debian
  # match
  if ($::osfamily == 'Debian') {
    file { '/etc/unbound/conf.d':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0775',
      require => Package['unbound'],
    }

    file { '/etc/unbound/unbound.conf':
      ensure  => present,
      source  => 'puppet:///modules/unbound/unbound.conf.debian',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      require => File['/etc/unbound/conf.d'],
      notify  => Service['unbound']
    }
  }

  # Ubuntu uses resolvconf which sets this.  NOTE: Debian unknown.
  if ($::osfamily == 'RedHat') {
    # Rackspace uses static config files
    file { '/etc/resolv.conf':
      content => 'nameserver 127.0.0.1',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      require => Service['unbound']
    }

    # HPCloud uses dhclient
    exec { '/usr/bin/printf "\nsupersede domain-name-servers 127.0.0.1;\n" >> /etc/dhcp/dhclient-eth0.conf':
        unless => '/bin/grep -q "supersede domain-name-servers" /etc/dhcp/dhclient-eth0.conf'
    }
  }

  service { 'unbound':
    name       => 'unbound',
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => Package['unbound'],
  }
}
