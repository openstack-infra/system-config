# == Class: stunnel
#
class stunnel (
  $ssl_cert_file = "",
  $ssl_key_file = "",
  $ssl_chain_file = "",
  # Connections are in the form:
  #   [["name", "source:port", "dest:port"], ...]
  $connections = [],
  $log_directory = '/var/log/stunnel4',
  $pid_directory = '/var/run/stunnel4',
){
  # Set up stunnel on the jenkins masters
  #
  # This sets up the stunnel service in preparation for the switch to SSL
  # for gearman. The jenkins gearman plugin doesn't support connecting to
  # a gearman server over SSL, so instead it will connect locally to the
  # listening stunnel service which will deal with the SSL wrapping of
  # the TCP connection.
  #
  # The service is currently stopped, as it isn't needed until we hit
  # the big SSL switch.
  #
  # When ready a patch set is required to start the stunnel service:
  #     ensure => running
  #
  # And we need to be sure the SSL cert, key _and_ CA is placed
  # in the required locations (2 of the three should already be in
  # place for apache):
  #     $ssl_cert_file
  #     $ssl_key_file
  #     $ssl_chain_file
  #
  package { 'stunnel4':
    ensure => present,
  }

  group { 'stunnel4':
    ensure => present,
  }

  user { 'stunnel4':
    ensure  => present,
    shell   => '/bin/false',
    gid     => 'stunnel4',
    require => Group['stunnel4'],
  }

  service { 'stunnel4':
    ensure  => stopped,
    has_restart => True,
    reuiqre => [
      Package['tunnel4'],
      User['stunnel4'],
      File['/etc/default/stunnel4'],
      File['/etc/stunnel/stunnel.conf'],
    ]
  }

  file { '/etc/default/stunnel4':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['stunnel4'],
    source => 'puppet:///modules/stunnel/default_stunnel',
  }

  file { '/etc/stunnel/stunnel.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify => Service['stunnel4'],
    content => template('stunnel/stunnel.conf.erb'),
  }

  file { $log_directory:
    ensure  => directory,
    mode    => '0755',
    uid     => 'stunnel4',
    gid     => 'stunnel4',
    require => User['stunnel4'],
  }

  file { $pid_directory:
    ensure  => directory,
    mode    => '0755',
    uid     => 'stunnel4',
    gid     => 'stunnel4',
    require => User['stunnel4'],
  }
}
