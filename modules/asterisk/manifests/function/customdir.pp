# == Define: asterisk::function::customdir
#
# This class manages the asterisk server
#
# === Examples
#
#  asterisk::function::customdir { 'cdr.conf': }
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
define asterisk::function::customdir(
) {
  include asterisk

  File {
    group => 'asterisk',
    mode  => '0640',
    owner => 'asterisk',
  }

  $basedir = '/etc/asterisk'
  $base = "${basedir}/${name}.d"

  file { $base:
    ensure  => directory,
    force   => true,
    notify  => Exec["asterisk-module-reload-${name}"],
    purge   => true,
    recurse => true,
    require => [
      File[$basedir],
      Service['asterisk'],
    ]
  }
}

# vim:sw=2:ts=2:expandtab
