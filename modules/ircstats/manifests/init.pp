# Install and manage log analyzer for irc logs.
class ircstats {

  #include apache
  package { ['php',
    'php-mbstring',
    'php-pdo']:
    ensure  => present,
  }

  user { 'ircstats':
    ensure     => present,
    home       => '/home/ircstats',
    shell      => '/bin/bash',
    gid        => 'ircstats',
    managehome => true,
    require    => Group['ircstats'],
  }

  group { 'ircstats':
    ensure => present,
  }

  file { '/etc/ircstats':
    ensure  => directory,
    owner   => 'ircstats',
    group   => 'ircstats',
    require => User['ircstats'],
  }

  # template to generate configuration for each channel
  file { '/etc/ircstats/ircstats.conf.template':
    ensure  => present,
    owner   => 'ircstats',
    group   => 'ircstats',
    mode    => '0644',
    require => File['/etc/ircstats'],
    source  => 'puppet:///modules/ircstats/ircstats.conf.template',
  }

  # stats install directory
  file { '/opt/ircstats':
    ensure  => directory,
    owner   => 'ircstats',
    group   => 'ircstats',
  }

  # stat generation script
  file { '/usr/local/bin/ircstats.py':
    ensure  => present,
    owner   => 'ircstats',
    group   => 'ircstats',
    mode    => '0755',
    source  => 'puppet:///modules/ircstats/ircstats.py',
  }

  cron { 'ircstats':
    user    => 'ircstats',
    hour    => '*',
    minute  => '0',
    command => 'python /usr/local/bin/ircstats.py -l /var/lib/statusbot/www -t /etc/ircstats/ircstats.conf.template -i /var/lib/statusbot/www/stats',
  }
}
