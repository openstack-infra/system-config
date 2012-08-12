class meetbot {

  include apache

  vcsrepo { "/opt/meetbot":
    ensure => latest,
    provider => git,
    source => "https://github.com/openstack-ci/meetbot.git",
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

  package { ['supybot', 'python-twisted']:
    ensure => present
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
    require => [Package["supybot"],
                Vcsrepo["/opt/meetbot"]]
  }

  file { "/etc/nginx/sites-enabled/default":
    ensure => absent,
    require => Package['nginx'],
    notify => Service['nginx']
  }

}
