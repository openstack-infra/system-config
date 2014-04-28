# == Class: gerritbot
#
class gerritbot(
  $nick = '',
  $password = '',
  $server = '',
  $user = '',
  $vhost_name = '',
  $ssh_rsa_key_contents = '',
  $ssh_rsa_pubkey_contents = '',
) {
  include pip

  package { 'gerritbot':
    ensure   => present,  # Pip upgrade is not working
    provider => pip,
    require  => Class['pip'],
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
      File['/etc/gerritbot/channel_config.yaml'],
    ],
  }

  file { '/etc/gerritbot':
    ensure => directory,
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
    require => User['gerrit2'],
  }

  if $ssh_rsa_key_contents != '' {
    file { '/home/gerrit2/.ssh/gerritbot_rsa':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $ssh_rsa_key_contents,
      replace => true,
      require => File['/home/gerrit2/.ssh']
    }
  }

  if $ssh_rsa_pubkey_contents != '' {
    file { '/home/gerrit2/.ssh/gerritbot_rsa.pub':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => $ssh_rsa_pubkey_contents,
      replace => true,
      require => File['/home/gerrit2/.ssh']
    }
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
