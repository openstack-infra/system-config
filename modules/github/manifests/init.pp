class github (
              $username,
              $oauth_token,
              $projects = []
             ) {

  include pip

  package { "PyGithub":
    ensure => latest,  # okay to use latest for pip
    provider => pip,
    require => Class[pip]
  }

  # A lot of things need yaml, be conservative requiring this package to avoid
  # conflicts with other modules.
  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
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
    ensure => absent
  }

  file { '/etc/github/github.secure.config':
    owner => 'root',
    group => 'github',
    mode => 440,
    ensure => 'present',
    content => template('github/github.secure.config.erb'),
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
    require => [
                 File['/usr/local/github/scripts'],
                 Package['python-yaml'],
                 Package['PyGithub'],
               ],
  }
}
