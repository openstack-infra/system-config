class gerritbot(
  $nick,
  $password,
  $server,
  $user,
  $vhost_name
) {

  include pip

  package { 'gerritbot':
    ensure   => present,  # Pip upgrade is not working
    provider => pip,
    require  => Class[pip]
  }

  file { '/etc/init.d/gerritbot':
    ensure  => present,
    group   => 'root',
    mode    => '0555',
    owner   => 'root',
    require => Package['gerritbot'],
    source  => 'puppet:///modules/gerritbot/gerritbot.init',
  }

  service { 'gerritbot':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/gerritbot'],
    subscribe  => [
      Package['gerritbot'],
      File['/etc/gerritbot/gerritbot.config'],
      File['/etc/gerritbot/channel_config.yaml']
    ],
  }

  file { '/etc/gerritbot':
    ensure => directory
  }

  file { '/var/log/gerritbot':
    ensure => directory,
    group  => 'gerrit2',
    mode   => '0775',
    owner  => 'root',
  }

  file { '/etc/gerritbot/channel_config.yaml':
    ensure  => present,
    group   => 'gerrit2',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['gerrit2'],
    source  => 'puppet:///modules/gerritbot/gerritbot_channel_config.yaml',
  }

  file { '/etc/gerritbot/logging.config':
    ensure  => present,
    group   => 'gerrit2',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['gerrit2'],
    source  => 'puppet:///modules/gerritbot/logging.config',
  }

  file { '/etc/gerritbot/gerritbot.config':
    ensure  => present,
    content => template('gerritbot/gerritbot.config.erb'),
    group   => 'gerrit2',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['gerrit2']
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
