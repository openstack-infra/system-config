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
    # This file differs from that in the package only by setting
    # RESOLVCONF_FORWARDERS to false.
    file { '/etc/default/unbound':
      source  => 'puppet:///modules/unbound/unbound.default',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
    }

    # We require the defaults file be in place before installing the
    # package to work around this bug:
    # https://bugs.launchpad.net/ubuntu/+source/unbound/+bug/988513
    # where we could end up briefly forwarding to a provider's broken
    # DNS.
    package { 'unbound':
      ensure  => present,
      require => File['/etc/default/unbound'],
    }

    # Tripleo uses dhcp
    file { '/etc/dhcp/dhclient.conf':
      source  => 'puppet:///modules/unbound/dhclient.conf.debian',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
    }
  }

  # Ubuntu uses resolvconf which will update resolv.conf to point to
  # localhost after unbound is installed.  NOTE: Debian unknown.
  if ($::osfamily == 'RedHat') {
    package { 'unbound':
      ensure  => present,
    }

    # HPCloud uses dhclient; tell dhclient to use our nameserver instead.
    exec { '/usr/bin/printf "\nsupersede domain-name-servers 127.0.0.1;\n" >> /etc/dhcp/dhclient-eth0.conf':
        unless => '/bin/grep -q "supersede domain-name-servers" /etc/dhcp/dhclient-eth0.conf'
    }
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

  service { 'unbound':
    ensure     => running,
    name       => 'unbound',
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    require    => Package['unbound'],
  }
}
