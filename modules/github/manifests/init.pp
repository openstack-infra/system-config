class github (
              $username,
              $oauth_token,
              $projects = []
             ) {

  package { "python-dev":
    ensure => present,
  }

  package { "python-pip":
    ensure => present,
    require => Package[python-dev]
  }

  package { "PyGithub":
    ensure => latest,  # okay to use latest for pip
    provider => pip,
    require => Package[python-pip]
  }

  group { "github":
    ensure => present
  }

  user { "github":
    ensure => present,
    comment => "Github API User",
    shell => "/bin/bash",
    gid => "github",
    require => Group["github"]
  }

  file { '/etc/github':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
  }

  file { '/etc/github/github.config':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    content => template('github/github.config.erb'),
    replace => 'true',
    require => File['/etc/github'],
  }

  file { '/etc/github/github.secure.config':
    owner => 'root',
    group => 'github',
    mode => 440,
    ensure => 'present',
    content => template('gerrit/github.secure.config.erb'),
    replace => 'true',
    require => [Group['github'], File['/etc/github']],
  }

  file { '/usr/local/github':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
  }

  file { '/usr/local/github/scripts':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    require => File['/usr/local/github'],
    source => [
                "puppet:///modules/github/scripts",
              ],
  }

  cron { "githubclosepull":
    user => github,
    minute => "*/5",
    command => 'sleep $((RANDOM\%60+90)) && python /usr/local/github/scripts/close_pull_requests.py',
    require => File['/usr/local/github/scripts'],
  }

}
