class gerritbot(
      $nick,
      $password,
      $server,
      $user,
      $vhost_name
      ) {

    file { "/usr/local/gerrit/gerritbot":
      owner => 'root',
      group => 'root',
      mode => 555,
      ensure => 'present',
      source => 'puppet:///modules/gerritbot/gerritbot',
      require => File['/usr/local/gerrit'],
    }

    file { "/etc/init.d/gerritbot":
      owner => 'root',
      group => 'root',
      mode => 555,
      ensure => 'present',
      source => 'puppet:///modules/gerritbot/gerritbot.init',
      require => File['/usr/local/gerrit/gerritbot'],
    }

    file { "/home/gerrit2/gerritbot_channel_config.yaml":
      owner   => 'root',
      group   => 'gerrit2',
      mode    => 440,
      ensure  => 'present',
      source  => 'puppet:///modules/gerritbot/gerritbot_channel_config.yaml',
      replace => true,
      require => User['gerrit2'],
    }

    service { 'gerritbot':
      name       => 'gerritbot',
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require => File['/etc/init.d/gerritbot'],
      subscribe => [File["/usr/local/gerrit/gerritbot"],
                    File["/home/gerrit2/gerritbot_channel_config.yaml"]],
    }

    file { '/home/gerrit2/gerritbot.config':
      owner => 'root',
      group => 'gerrit2',
      mode => 440,
      ensure => 'present',
      content => template('gerritbot/gerritbot.config.erb'),
      replace => 'true',
      require => User['gerrit2']
    }

}
