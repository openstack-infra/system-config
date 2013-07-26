# == Class: asterisk::server::command
#
# === Authors
#
# Paul Belanger <paul.belanger@polybeacon.com>
#
# === Copyright
#
# Copyright (C) 2012, PolyBeacon, Inc.
#
# This program is free software, distributed under the terms
# of the Apache License, Version 2.0. See the LICENSE file at
# the top of the source tree.
#
class asterisk::server::command {
  exec { 'asterisk-module-reload-ais.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-amd.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-asterisk.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-calendar.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-ccss.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cdr_adaptive_odbc.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cdr.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cdr_custom.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cdr_manager.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cdr_syslog.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cel.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cel_custom.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cel_odbc.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-chan_dahdi.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cli.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-cli_permissions.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-codecs.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-dnsmgr.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-dsp.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-dundi.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-enum.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-extconfig.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-extensions.conf':
    command     => '/usr/sbin/asterisk -rx "dialplan reload"',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-features.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-func_odbc.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-gtalk.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-http.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-iax.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-iaxprov.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-indications.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-jabber.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-logger.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-manager.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-meetme.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  # Force asterisk to restart to load / unload modules.
  exec { 'asterisk-module-reload-modules.conf':
    command     => '/bin/true',
    notify      => Service['asterisk'],
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-musiconhold.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-queuerules.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-queues.conf':
    command     => '/usr/sbin/asterisk -rx "module reload app_queue.so"',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-res_curl.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-res_fax.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-res_ldap.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-res_odbc.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-res_stun_monitor.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-rtp.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-say.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-sip.conf':
    command     => '/usr/sbin/asterisk -rx "module reload chan_sip.so"',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-sip_notify.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-smdi.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-udptl.conf':
    command     => '/bin/true',
    refreshonly => true,
  }

  exec { 'asterisk-module-reload-voicemail.conf':
    command     => '/usr/sbin/asterisk -rx "module reload app_voicemail.so"',
    refreshonly => true,
  }
}

# vim:sw=2:ts=2:expandtab
