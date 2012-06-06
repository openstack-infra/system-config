class vcs {
# if we already have the git repo the pull updates

  exec { "update_meetbot_repo":
    command => "git pull --ff-only",
    cwd => "/opt/meetbot",
    path => "/bin:/usr/bin",
    onlyif => "test -d /opt/meetbot"
  }

# otherwise get a new clone of it

  exec { "clone_meebot_repo":
    command => "git clone https://github.com/openstack-ci/meetbot.git /opt/meetbot",
    path => "/bin:/usr/bin",
    onlyif => "test ! -d /opt/meetbot"
  }
}

class meetbot {
  stage { 'first': before => Stage['main'] }
  class { 'vcs':
    stage => 'first'
  }

  user { "meetbot":
    shell => "/sbin/nologin",
    home => "/var/lib/meetbot",
    system => true,
    gid => "meetbot",
    require => Group["meetbot"]
  }

  group { "meetbot":
    ensure => present
  }

  package { ['supybot', 'nginx', 'python-twisted']:
    ensure => present
  }

  service { "nginx":
    ensure => running,
    hasrestart => true
  }

  file { "/var/lib/meetbot":
    ensure => directory,
    owner => 'meetbot',
    require => User['meetbot']
  }

  file { "/usr/share/pyshared/supybot/plugins/MeetBot":
    ensure => directory,
    recurse => true,
    source => "/opt/meetbot/MeetBot",
    require => Package["supybot"]
  }

  file { "/etc/nginx/sites-enabled/default":
    ensure => absent,
    require => Package['nginx'],
    notify => Service['nginx']
  }

}
