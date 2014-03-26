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
  include asterisk::server::command

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

  $sounds = [
    'asterisk-sounds-core-en-g722',
    'asterisk-sounds-core-en-ulaw',
    'asterisk-sounds-core-en-gsm',
    'asterisk-sounds-extra-en-ulaw',
    'asterisk-sounds-extra-en-gsm',
    'asterisk-sounds-moh-opsound-wav',
    'asterisk-sounds-moh-opsound-ulaw',
  ]

  package { $sounds :
    ensure  => present,
    require => Yumrepo['asteriskcurrent'],
  }

  file { '/etc/asterisk/asterisk.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => $asterisk_conf_source,
  }

  file { '/etc/asterisk/modules.conf.d/modules.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => $modules_conf_source,
  }

  file { '/etc/asterisk':
    ensure  => present,
    recurse => true,
    purge   => true,
    force   => true,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/',
    require => Package['asterisk'],
  }

  $files = [
    'ais.conf', 'amd.conf', 'asterisk.conf', 'calendar.conf', 'ccss.conf',
    'cdr_adaptive_odbc.conf', 'cdr.conf', 'cdr_custom.conf',
    'cdr_manager.conf', 'cdr_syslog.conf', 'cel.conf', 'cel_custom.conf',
    'cel_odbc.conf', 'chan_dahdi.conf', 'cli.conf', 'cli_permissions.conf',
    'codecs.conf', 'dnsmgr.conf', 'dsp.conf', 'dundi.conf', 'enum.conf',
    'extconfig.conf', 'extensions.conf', 'features.conf', 'func_odbc.conf',
    'gtalk.conf', 'http.conf', 'iax.conf', 'iaxprov.conf',
    'indications.conf', 'jabber.conf', 'logger.conf', 'manager.conf',
    'meetme.conf', 'modules.conf', 'musiconhold.conf', 'queuerules.conf',
    'queues.conf', 'res_curl.conf', 'res_fax.conf', 'res_ldap.conf',
    'res_odbc.conf', 'res_stun_monitor.conf', 'rtp.conf', 'say.conf',
    'sip.conf', 'sip_notify.conf', 'smdi.conf', 'udptl.conf',
    'voicemail.conf',
  ]

  asterisk::function::customdir { $files: }

  service { 'asterisk':
    ensure  => running,
    enable  => true,
    require => [
      Package['asterisk'],
      File['/etc/asterisk/'],
    ]
  }
}
