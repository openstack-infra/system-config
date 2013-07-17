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

  package { 'asterisk' :
    ensure  => present,
    require => Yumrepo['asterisk11'],
  }

  package { 'asterisk-sounds-moh-opsound-ulaw' :
    ensure  => present,
    require => Yumrepo['asteriskcurrent'],
  }

  package { 'asterisk-sounds-core-en-ulaw' :
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

  file {'/etc/asterisk/ais.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/ais.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/ais.conf',
    require => File['/etc/asterisk/ais.conf.d'],
  }

  file {'/etc/asterisk/amd.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/amd.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/amd.conf',
    require => File['/etc/asterisk/amd.conf.d'],
  }

  file {'/etc/asterisk/calendar.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/calendar.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/calendar.conf',
    require => File['/etc/asterisk/calendar.conf.d'],
  }

  file {'/etc/asterisk/ccss.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/ccss.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/ccss.conf',
    require => File['/etc/asterisk/ccss.conf.d'],
  }

  file {'/etc/asterisk/cdr_adaptive_odbc.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cdr_adaptive_odbc.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cdr_adaptive_odbc.conf',
    require => File['/etc/asterisk/cdr_adaptive_odbc.conf.d'],
  }

  file {'/etc/asterisk/cdr.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cdr.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cdr.conf',
    require => File['/etc/asterisk/cdr.conf.d'],
  }

  file {'/etc/asterisk/cdr_custom.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cdr_custom.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cdr_custom.conf',
    require => File['/etc/asterisk/cdr_custom.conf.d'],
  }

  file {'/etc/asterisk/cdr_manager.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cdr_manager.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cdr_manager.conf',
    require => File['/etc/asterisk/cdr_manager.conf.d'],
  }

  file {'/etc/asterisk/cdr_syslog.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cdr_syslog.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cdr_syslog.conf',
    require => File['/etc/asterisk/cdr_syslog.conf.d'],
  }

  file {'/etc/asterisk/cel.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cel.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cel.conf',
    require => File['/etc/asterisk/cel.conf.d'],
  }

  file {'/etc/asterisk/cel_custom.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cel_custom.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cel_custom.conf',
    require => File['/etc/asterisk/cel_custom.conf.d'],
  }

  file {'/etc/asterisk/cel_odbc.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cel_odbc.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cel_odbc.conf',
    require => File['/etc/asterisk/cel_odbc.conf.d'],
  }

  file {'/etc/asterisk/chan_dahdi.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/chan_dahdi.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/chan_dahdi.conf',
    require => File['/etc/asterisk/chan_dahdi.conf.d'],
  }

  file {'/etc/asterisk/cli.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cli.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cli.conf',
    require => File['/etc/asterisk/cli.conf.d'],
  }

  file {'/etc/asterisk/cli_permissions.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/cli_permissions.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/cli_permissions.conf',
    require => File['/etc/asterisk/cli_permissions.conf.d'],
  }

  file {'/etc/asterisk/codecs.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/codecs.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/codecs.conf',
    require => File['/etc/asterisk/codecs.conf.d'],
  }

  file {'/etc/asterisk/dnsmgr.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/dnsmgr.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/dnsmgr.conf',
    require => File['/etc/asterisk/dnsmgr.conf.d'],
  }

  file {'/etc/asterisk/dsp.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/dsp.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/dsp.conf',
    require => File['/etc/asterisk/dsp.conf.d'],
  }

  file {'/etc/asterisk/dundi.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/dundi.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/dundi.conf',
    require => File['/etc/asterisk/dundi.conf.d'],
  }

  file {'/etc/asterisk/enum.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/enum.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/enum.conf',
    require => File['/etc/asterisk/enum.conf.d'],
  }

  file {'/etc/asterisk/extconfig.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/extconfig.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/extconfig.conf',
    require => File['/etc/asterisk/extconfig.conf.d'],
  }

  file {'/etc/asterisk/extensions.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/extensions.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/extensions.conf',
    require => File['/etc/asterisk/extensions.conf.d'],
  }

  file {'/etc/asterisk/features.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/features.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/features.conf',
    require => File['/etc/asterisk/features.conf.d'],
  }

  file {'/etc/asterisk/func_odbc.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/func_odbc.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/func_odbc.conf',
    require => File['/etc/asterisk/func_odbc.conf.d'],
  }

  file {'/etc/asterisk/gtalk.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/gtalk.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/gtalk.conf',
    require => File['/etc/asterisk/gtalk.conf.d'],
  }

  file {'/etc/asterisk/http.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/http.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/http.conf',
    require => File['/etc/asterisk/http.conf.d'],
  }

  file {'/etc/asterisk/iax.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/iax.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/iax.conf',
    require => File['/etc/asterisk/iax.conf.d'],
  }

  file {'/etc/asterisk/iaxprov.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/iaxprov.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/iaxprov.conf',
    require => File['/etc/asterisk/iaxprov.conf.d'],
  }

  file {'/etc/asterisk/indications.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/indications.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/indications.conf',
    require => File['/etc/asterisk/indications.conf.d'],
  }

  file {'/etc/asterisk/jabber.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/jabber.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/jabber.conf',
    require => File['/etc/asterisk/jabber.conf.d'],
  }

  file {'/etc/asterisk/logger.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/logger.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/logger.conf',
    require => File['/etc/asterisk/logger.conf.d'],
  }

  file {'/etc/asterisk/manager.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/manager.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/manager.conf',
    require => File['/etc/asterisk/manager.conf.d'],
  }

  file {'/etc/asterisk/meetme.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/meetme.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/meetme.conf',
    require => File['/etc/asterisk/meetme.conf.d'],
  }

  file {'/etc/asterisk/musiconhold.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/musiconhold.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/musiconhold.conf',
    require => File['/etc/asterisk/musiconhold.conf.d'],
  }

  file {'/etc/asterisk/queuerules.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/queuerules.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/queuerules.conf',
    require => File['/etc/asterisk/queuerules.conf.d'],
  }

  file {'/etc/asterisk/queues.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/queues.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/queues.conf',
    require => File['/etc/asterisk/queues.conf.d'],
  }

  file {'/etc/asterisk/res_curl.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/res_curl.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/res_curl.conf',
    require => File['/etc/asterisk/res_curl.conf.d'],
  }

  file {'/etc/asterisk/res_fax.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/res_fax.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/res_fax.conf',
    require => File['/etc/asterisk/res_fax.conf.d'],
  }

  file {'/etc/asterisk/res_ldap.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/res_ldap.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/res_ldap.conf',
    require => File['/etc/asterisk/res_ldap.conf.d'],
  }

  file {'/etc/asterisk/res_odbc.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/res_odbc.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/res_odbc.conf',
    require => File['/etc/asterisk/res_odbc.conf.d'],
  }

  file {'/etc/asterisk/res_stun_monitor.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/res_stun_monitor.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/res_stun_monitor.conf',
    require => File['/etc/asterisk/res_stun_monitor.conf.d'],
  }

  file {'/etc/asterisk/rtp.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/rtp.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/rtp.conf',
    require => File['/etc/asterisk/rtp.conf.d'],
  }

  file {'/etc/asterisk/say.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/say.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/say.conf',
    require => File['/etc/asterisk/say.conf.d'],
  }

  file {'/etc/asterisk/sip.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/sip.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/sip.conf',
    require => File['/etc/asterisk/sip.conf.d'],
  }

  file {'/etc/asterisk/sip_notify.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/sip_notify.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/sip_notify.conf',
    require => File['/etc/asterisk/sip_notify.conf.d'],
  }

  file {'/etc/asterisk/smdi.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/smdi.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/smdi.conf',
    require => File['/etc/asterisk/smdi.conf.d'],
  }

  file {'/etc/asterisk/udptl.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/udptl.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/udptl.conf',
    require => File['/etc/asterisk/udptl.conf.d'],
  }

  file {'/etc/asterisk/voicemail.conf.d':
    ensure => directory,
    owner  => 'asterisk',
    group  => 'asterisk',
  }

  file {'/etc/asterisk/voicemail.conf':
    ensure  => present,
    owner   => 'asterisk',
    group   => 'asterisk',
    mode    => '0660',
    source  => 'puppet:///modules/asterisk/voicemail.conf',
    require => File['/etc/asterisk/voicemail.conf.d'],
  }

  service { 'asterisk':
    ensure  => running,
    enable  => true,
    require => [
      Package['asterisk'],
      File['/etc/asterisk/ais.conf'],
      File['/etc/asterisk/amd.conf'],
      File['/etc/asterisk/asterisk.conf'],
      File['/etc/asterisk/calendar.conf'],
      File['/etc/asterisk/ccss.conf'],
      File['/etc/asterisk/cdr_adaptive_odbc.conf'],
      File['/etc/asterisk/cdr.conf'],
      File['/etc/asterisk/cdr_custom.conf'],
      File['/etc/asterisk/cdr_manager.conf'],
      File['/etc/asterisk/cdr_syslog.conf'],
      File['/etc/asterisk/cel.conf'],
      File['/etc/asterisk/cel_custom.conf'],
      File['/etc/asterisk/cel_odbc.conf'],
      File['/etc/asterisk/chan_dahdi.conf'],
      File['/etc/asterisk/cli.conf'],
      File['/etc/asterisk/cli_permissions.conf'],
      File['/etc/asterisk/codecs.conf'],
      File['/etc/asterisk/dnsmgr.conf'],
      File['/etc/asterisk/dsp.conf'],
      File['/etc/asterisk/dundi.conf'],
      File['/etc/asterisk/enum.conf'],
      File['/etc/asterisk/extconfig.conf'],
      File['/etc/asterisk/extensions.conf'],
      File['/etc/asterisk/features.conf'],
      File['/etc/asterisk/func_odbc.conf'],
      File['/etc/asterisk/gtalk.conf'],
      File['/etc/asterisk/http.conf'],
      File['/etc/asterisk/iax.conf'],
      File['/etc/asterisk/iaxprov.conf'],
      File['/etc/asterisk/indications.conf'],
      File['/etc/asterisk/jabber.conf'],
      File['/etc/asterisk/logger.conf'],
      File['/etc/asterisk/manager.conf'],
      File['/etc/asterisk/meetme.conf'],
      File['/etc/asterisk/modules.conf'],
      File['/etc/asterisk/musiconhold.conf'],
      File['/etc/asterisk/queuerules.conf'],
      File['/etc/asterisk/queues.conf'],
      File['/etc/asterisk/res_curl.conf'],
      File['/etc/asterisk/res_fax.conf'],
      File['/etc/asterisk/res_ldap.conf'],
      File['/etc/asterisk/res_odbc.conf'],
      File['/etc/asterisk/res_stun_monitor.conf'],
      File['/etc/asterisk/rtp.conf'],
      File['/etc/asterisk/say.conf'],
      File['/etc/asterisk/sip.conf'],
      File['/etc/asterisk/sip_notify.conf'],
      File['/etc/asterisk/smdi.conf'],
      File['/etc/asterisk/udptl.conf'],
      File['/etc/asterisk/voicemail.conf'],
    ]
  }
}
