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
# recursive resolver.

class unbound (
) {

  if ($::osfamily == 'Debian') {
    file { '/etc/default/unbound':
      source  => 'puppet:///modules/unbound/unbound.default',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
    }

    package { 'unbound':
      ensure  => present,
      require => File['/etc/default/unbound'],
    }
  }

  # Ubuntu uses resolvconf which sets this.  NOTE: Debian unknown.
  if ($::osfamily == 'RedHat') {
    package { 'unbound':
      ensure  => present,
    }

    # Rackspace uses static config files
    file { '/etc/resolv.conf':
      content => "nameserver 127.0.0.1\n",
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      require => Service['unbound'],
      notify  => Exec['make-resolv-conf-immutable'],
    }

    exec { 'make-resolv-conf-immutable':
      command     => '/usr/bin/chattr +i /etc/resolv.conf',
      refreshonly => true,
    }

    # HPCloud uses dhclient
    exec { '/usr/bin/printf "\nsupersede domain-name-servers 127.0.0.1;\n" >> /etc/dhcp/dhclient-eth0.conf':
        unless => '/bin/grep -q "supersede domain-name-servers" /etc/dhcp/dhclient-eth0.conf'
    }
  }

  service { 'unbound':
    ensure     => running,
    name       => 'unbound',
    enable     => true,
    hasrestart => true,
    require    => Package['unbound'],
  }
}
