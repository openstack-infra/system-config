# Copyright 2013 Red Hat, Inc.
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
# Class to configure asterisk on a CentOS node.
#
# Note that every node must provide its own asterisk.conf and modules.conf files.
# All other configuration customizations should be done as overrides to the default
# configuration by dropping files into the appropriate conf.d directory.
#
# == Class: asterisk
class asterisk (
  $asterisk_conf_source = '',
  $modules_conf_source  = '',
) {
  yumrepo { 'asteriskcurrent':
    baseurl  => 'http://packages.asterisk.org/centos/$releasever/current/$basearch/',
    descr    => 'Asterisk supporting packages produced by Digium',
    enabled  => 1,
    gpgcheck => 0,
  }

  yumrepo { 'asterisk11':
    baseurl  => 'http://packages.asterisk.org/centos/$releasever/asterisk-11/$basearch/',
    descr    => 'Asterisk packages produced by Digium',
    enabled  => 1,
    gpgcheck => 0,
    require  => Yumrepo['asteriskcurrent'],
  }

  package { 'asterisknow-version' :
    ensure  => present,
    require => [
      Yumrepo['asteriskcurrent'],
    ],
  }

  package { 'asterisk' :
    ensure  => present,
    require => [
      Yumrepo['asterisk11'],
      Package['asterisknow-version'],
    ],
  }

  package { 'asterisk-sounds-moh-opsound-ulaw' :
    ensure  => present,
    require => Yumrepo['asteriskcurrent'],
  }

  package { 'asterisk-sounds-core-en-ulaw' :
    ensure  => present,
    require => Yumrepo['asteriskcurrent'],
  }

  package { 'asterisk-sounds-extra-en-ulaw' :
    ensure  => present,
    require => Yumrepo['asteriskcurrent'],
  }

  file {'/etc/asterisk/asterisk.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => $asterisk_conf_source,
  }

  file {'/etc/asterisk/modules.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => $modules_conf_source,
  }

  file {'/etc/asterisk/':
    ensure  => present,
    recurse => true,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/',
    require => Package['asterisk'],
  }

  service { 'asterisk':
    ensure  => running,
    enable  => true,
    require => [
      Package['asterisk'],
      File['/etc/asterisk/'],
    ]
  }
}
