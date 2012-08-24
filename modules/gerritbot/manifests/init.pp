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
    owner   => 'root',
    group   => 'root',
    mode    => 555,
    ensure  => 'present',
    source  => 'puppet:///modules/gerritbot/gerritbot.init',
    require => Package['gerritbot'],
  }

  service { 'gerritbot':
    name       => 'gerritbot',
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/gerritbot'],
    subscribe  => [Package['gerritbot'],
                   File['/etc/gerritbot/gerritbot.config'],
                   File['/etc/gerritbot/channel_config.yaml']],
  }

  file { '/etc/gerritbot':
    ensure => directory
  }

  file { '/var/log/gerritbot':
    ensure => directory,
    owner  => 'root',
    group  => 'gerrit2',
    mode    => 0775,
  }

  file { '/etc/gerritbot/channel_config.yaml':
    owner   => 'root',
    group   => 'gerrit2',
    mode    => 440,
    ensure  => 'present',
    source  => 'puppet:///modules/gerritbot/gerritbot_channel_config.yaml',
    replace => true,
    require => User['gerrit2'],
  }

  file { '/etc/gerritbot/logging.config':
    owner   => 'root',
    group   => 'gerrit2',
    mode    => 440,
    ensure  => 'present',
    source  => 'puppet:///modules/gerritbot/logging.config',
    replace => true,
    require => User['gerrit2'],
  }

  file { '/etc/gerritbot/gerritbot.config':
    owner   => 'root',
    group   => 'gerrit2',
    mode    => 440,
    ensure  => 'present',
    content => template('gerritbot/gerritbot.config.erb'),
    replace => 'true',
    require => User['gerrit2']
  }

}
