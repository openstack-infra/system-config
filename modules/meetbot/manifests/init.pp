class meetbot {
  include apache

  vcsrepo { '/opt/meetbot':
    ensure   => latest,
    provider => git,
    source   => 'https://git.openstack.org/openstack-infra/meetbot',
  }

  vcsrepo { '/opt/supybot_plugins':
    ensure   => latest,
    provider => bzr,
    source   => 'lp:ubuntu-bots',
 }

  user { 'meetbot':
    gid     => 'meetbot',
    home    => '/var/lib/meetbot',
    shell   => '/sbin/nologin',
    system  => true,
    require => Group['meetbot'],
  }

  group { 'meetbot':
    ensure => present,
  }

  $packages = [
    'supybot',
    'python-twisted',
    'SOAPpy'
  ]

  package { $packages:
    ensure => present,
  }

  file { '/var/lib/meetbot':
    ensure  => directory,
    owner   => 'meetbot',
    require => User['meetbot'],
  }

  file { '/usr/share/pyshared/supybot/plugins/MeetBot':
    ensure  => directory,
    recurse => true,
    require => [
      Package['supybot'],
      Vcsrepo['/opt/meetbot']
    ],
    source  => '/opt/meetbot/MeetBot',
  }

  file { '/usr/share/pyshared/supybot/plugins/Bugtracker':
    ensure => directory,
    recurse => true,
    require => [
      Package['supybot'],
      Vcsrepo['/opt/supybot_plugins']
    ],
    source => /opt/supybot_plugins/Bugtracker',
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
