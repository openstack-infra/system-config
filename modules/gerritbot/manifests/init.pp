class gerritbot(
  $nick,
  $password,
  $server,
  $user,
  $virtual_hostname,
  $repo_dir
) {

  file { "${repo_dir}":
    ensure => directory
  }

  vcsrepo { "${repo_dir}/gerritbot":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/openstack-ci/gerritbot.git',
    require  => File["${repo_dir}"]
  }

  exec { 'install_gerritbot':
    command     => 'pip install --upgrade .'
    cwd         => "${repo_dir}/gerritbot",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo["${repo_dir}/gerritbot"]
  }

  file { '/etc/init.d/gerritbot':
    owner   => 'root',
    group   => 'root',
    mode    => 555,
    ensure  => 'present',
    source  => 'puppet:///modules/gerritbot/gerritbot.init',
    require => Exec['install_gerritbot'],
  }

  service { 'gerritbot':
    name       => 'gerritbot',
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/gerritbot'],
    subscribe  => [Exec['install_gerritbot'],
                   File['/home/gerrit2/gerritbot_channel_config.yaml']],
  }

  file { '/home/gerrit2/gerritbot_channel_config.yaml':
    owner   => 'root',
    group   => 'gerrit2',
    mode    => 440,
    ensure  => 'present',
    source  => 'puppet:///modules/gerritbot/gerritbot_channel_config.yaml',
    replace => true,
    require => User['gerrit2'],
  }

  file { '/home/gerrit2/gerritbot.config':
    owner   => 'root',
    group   => 'gerrit2',
    mode    => 440,
    ensure  => 'present',
    content => template('gerritbot/gerritbot.config.erb'),
    replace => 'true',
    require => User['gerrit2']
  }

}
