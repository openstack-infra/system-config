class exim(
  $mailman_domains = [],
  $queue_interval = '30m',
  $queue_run_max = '5',
  $queue_smtp_domains = '',
  $smarthost = false,
  $sysadmin = []
) {

  include exim::params

  package { $::exim::params::package:
    ensure => present,
  }

  if ($::osfamily == 'RedHat') {
    service { 'postfix':
      ensure      => stopped
    }
    file { $::exim::params::sysdefault_file:
      ensure  => present,
      content => template("${module_name}/exim.sysconfig.erb"),
      group   => 'root',
      mode    => '0444',
      owner   => 'root',
      replace => true,
      require => Package[$::exim::params::package],
    }
  }

  if ($::osfamily == 'Debian') {
    file { $::exim::params::sysdefault_file:
      ensure  => present,
      content => template("${module_name}/exim4.default.erb"),
      group   => 'root',
      mode    => '0444',
      owner   => 'root',
      replace => true,
      require => Package[$::exim::params::package],
    }
  }

  service { 'exim':
    ensure      => running,
    name        => $::exim::params::service_name,
    hasrestart  => true,
    subscribe   => [File[$::exim::params::config_file],
                    File[$::exim::params::sysdefault_file]],
    require     => Package[$::exim::params::package],
  }

  file { $::exim::params::config_file:
    ensure  => present,
    content => template("${module_name}/exim4.conf.erb"),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
    require => Package[$::exim::params::package],
  }

  file { '/etc/aliases':
    ensure  => present,
    content => template("${module_name}/aliases.erb"),
    group   => 'root',
    mode    => '0444',
    owner   => 'root',
    replace => true,
    require => Sysadmin_check['Check sysadmin'],
  }

  define sysadmin_check {
    if ($sysadmin == []) {
      user { 'sysadmin':
        ensure     => present,
        comment    => 'sysadmin default',
        shell      => '/bin/nologin',
        gid        => 'sysadmin',
        home       => '/home/sysadmin',
        managehome => true,
        require    => Group['sysadmin'],
      }

      group { 'sysadmin':
        ensure => present,
      }
    } else {
      user { 'sysadmin':
        ensure     => absent,
        comment    => 'sysadmin default',
        shell      => '/bin/nologin',
        gid        => 'sysadmin',
        home       => '/home/sysadmin',
        managehome => true,
      }

      group { 'sysadmin':
        ensure  => absent,
        require => User['sysadmin'],
      }
    }
  }

  sysadmin_check { 'Check sysadmin': }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
